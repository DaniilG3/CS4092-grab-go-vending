import psycopg2
import psycopg2.extras

def get_conn():
    return psycopg2.connect(dbname="grabgo_db", host="localhost")

def fetch_all(sql, params=None):
    with get_conn() as conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(sql, params or [])
        return cur.fetchall()

def execute(sql, params=None):
    with get_conn() as conn, conn.cursor() as cur:
        cur.execute(sql, params or [])
        conn.commit()

def run_txn(steps):
    with get_conn() as conn:
        try:
            with conn.cursor() as cur:
                for fn in steps:
                    fn(cur)
            conn.commit()
        except Exception:
            conn.rollback()
            raise

# CLI actions
def menu():
    print("\n=== Grab & Go CLI ===")
    print("1) Search active items")
    print("2) View machine stock")
    print("3) Low-stock report (< 5)")
    print("4) Dispense item")
    print("5) Restock machine")
    print("0) Exit")
    return input("Choose: ").strip()

def search_items():
    term = input("Keyword (name/category): ").strip()
    rows = fetch_all("""
        SELECT item_id, name, category, unit_cost, calories
        FROM item
        WHERE is_active = TRUE
          AND (name ILIKE %s OR category ILIKE %s)
        ORDER BY name LIMIT 50
    """, [f"%{term}%", f"%{term}%"])
    if not rows:
        print("No results."); return
    for r in rows:
        print(f"[{r['item_id']:>2}] {r['name']:<18} {r['category']:<8} ${r['unit_cost']}  {r['calories']} cal")

def view_machine_stock():
    mid = input("Machine ID: ").strip()
    rows = fetch_all("""
        SELECT i.item_id, i.name, s.qty
        FROM stock s
        JOIN item i ON i.item_id = s.item_id
        WHERE s.machine_id = %s
        ORDER BY i.name
    """, [mid])
    if not rows:
        print("No stock for that machine (or invalid ID)."); return
    for r in rows:
        print(f"{r['item_id']:>3}  {r['name']:<20}  qty={r['qty']}")

def low_stock():
    rows = fetch_all("""
        SELECT m.location, i.name, s.qty
        FROM stock s
        JOIN machine m ON m.machine_id = s.machine_id
        JOIN item i    ON i.item_id = s.item_id
        WHERE s.qty < 5
        ORDER BY m.location, i.name
    """)
    if not rows:
        print("No low-stock items."); return
    for r in rows:
        print(f"{r['location']:<28} {r['name']:<18} qty={r['qty']}")

def dispense_item():
    cid = input("Customer ID: ").strip()
    mid = input("Machine ID: ").strip()
    iid = input("Item ID: ").strip()

    def step_check_and_decrement(cur):
        cur.execute("SELECT status FROM machine WHERE machine_id=%s", [mid])
        row = cur.fetchone()
        if not row: raise ValueError("Machine not found.")
        if row[0] != 'active': raise ValueError("Machine is not active.")

        cur.execute("SELECT qty FROM stock WHERE machine_id=%s AND item_id=%s FOR UPDATE", [mid, iid])
        row = cur.fetchone()
        if not row or row[0] <= 0: raise ValueError("Out of stock.")
        cur.execute("UPDATE stock SET qty = qty - 1 WHERE machine_id=%s AND item_id=%s", [mid, iid])

    def step_insert_dispense(cur):
        cur.execute("SELECT unit_cost FROM item WHERE item_id=%s", [iid])
        row = cur.fetchone()
        price = row[0] if row else None
        cur.execute("""
            INSERT INTO dispense (customer_id, machine_id, item_id, ts, price_charged, payment_method)
            VALUES (%s,%s,%s, NOW(), %s, %s)
        """, [cid, mid, iid, price, 'card'])

    try:
        run_txn([step_check_and_decrement, step_insert_dispense])
        print("Dispensed successfully.")
    except Exception as e:
        print(f"Failed to dispense: {e}")

def restock_machine():
    sid = input("Staff ID: ").strip()
    mid = input("Machine ID: ").strip()
    print("Enter item_id,qty (e.g., 1,10). Blank line to finish.")
    lines = []
    while True:
        line = input("> ").strip()
        if not line: break
        try:
            iid_str, qty_str = [x.strip() for x in line.split(",")]
            lines.append((int(iid_str), int(qty_str)))
        except Exception:
            print("Bad format; use item_id,qty")

    if not lines:
        print("No lines entered."); return

    def step_header(cur):
        cur.execute("""
            INSERT INTO restock (staff_id, machine_id, ts)
            VALUES (%s,%s, NOW()) RETURNING restock_id
        """, [sid, mid])
        rid = cur.fetchone()[0]
        cur.restock_id = rid

    def step_lines_and_upsert(cur):
        rid = cur.restock_id
        for iid, qty in lines:
            cur.execute("INSERT INTO restockline (restock_id, item_id, qty) VALUES (%s,%s,%s)",
                        [rid, iid, qty])
            cur.execute("""
                INSERT INTO stock (machine_id, item_id, qty)
                VALUES (%s,%s,%s)
                ON CONFLICT (machine_id, item_id) DO UPDATE
                SET qty = stock.qty + EXCLUDED.qty
            """, [mid, iid, qty])

    try:
        run_txn([step_header, step_lines_and_upsert])
        print("Restock recorded.")
    except Exception as e:
        print(f"Failed to restock: {e}")

def main():
    actions = {
        "1": search_items,
        "2": view_machine_stock,
        "3": low_stock,
        "4": dispense_item,
        "5": restock_machine,
    }
    while True:
        choice = menu()
        if choice == "0":
            print("Bye."); break
        fn = actions.get(choice)
        if fn: fn()
        else: print("Unknown option.")

if __name__ == "__main__":
    main()