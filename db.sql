-- Creating the tables
CREATE TABLE Customer (
  customer_id   SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  eligibility   VARCHAR(30),
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Staff (
  staff_id      SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  role          VARCHAR(30) NOT NULL CHECK (role IN ('staff','admin'))
);

CREATE TABLE Machine (
  machine_id    SERIAL PRIMARY KEY,
  location      VARCHAR(255) NOT NULL,
  status        VARCHAR(20) NOT NULL CHECK (status IN ('active','maintenance','offline'))
);

CREATE TABLE Item (
  item_id       SERIAL PRIMARY KEY,
  name          VARCHAR(120) NOT NULL,
  category      VARCHAR(60),
  unit_cost     NUMERIC(6,2) NOT NULL CHECK (unit_cost >= 0),
  calories      INT CHECK (calories >= 0),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE Stock (
  machine_id    INT NOT NULL REFERENCES Machine(machine_id) ON DELETE CASCADE,
  item_id       INT NOT NULL REFERENCES Item(item_id) ON DELETE CASCADE,
  qty           INT NOT NULL CHECK (qty >= 0),
  PRIMARY KEY (machine_id, item_id)
);

CREATE TABLE Dispense (
  dispense_id    SERIAL PRIMARY KEY,
  customer_id    INT NOT NULL REFERENCES Customer(customer_id) ON DELETE CASCADE,
  machine_id     INT NOT NULL REFERENCES Machine(machine_id) ON DELETE CASCADE,
  item_id        INT NOT NULL REFERENCES Item(item_id) ON DELETE CASCADE,
  ts             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  price_charged  NUMERIC(6,2) CHECK (price_charged >= 0),
  payment_method VARCHAR(30)
);

CREATE TABLE Restock (
  restock_id    SERIAL PRIMARY KEY,
  staff_id      INT NOT NULL REFERENCES Staff(staff_id) ON DELETE CASCADE,
  machine_id    INT NOT NULL REFERENCES Machine(machine_id) ON DELETE CASCADE,
  ts            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE RestockLine (
  restock_id    INT NOT NULL REFERENCES Restock(restock_id) ON DELETE CASCADE,
  item_id       INT NOT NULL REFERENCES Item(item_id) ON DELETE CASCADE,
  qty           INT NOT NULL CHECK (qty > 0),
  PRIMARY KEY (restock_id, item_id)
);

-- Populating the tables
INSERT INTO Customer (name, email, eligibility) VALUES
('Alex Kim','alex@example.com','student'),
('Jordan Lee','jordan@example.com','community'),
('Sam Patel','sam@example.com','student'),
('Riley Chen','riley@example.com','community');

INSERT INTO Staff (name, email, role) VALUES
('Morgan Diaz','morgan@example.com','admin'),
('Taylor Brooks','taylor@example.com','staff');

INSERT INTO Machine (location, status) VALUES
('Union Building - Lobby','active'),
('Library - 1st Floor','active'),
('Rec Center - Entrance','maintenance');

INSERT INTO Item (name, category, unit_cost, calories, is_active) VALUES
('Granola Bar','snack',0.75,120,TRUE),
('Bottled Water','drink',0.00,0,TRUE),
('Apple','fruit',0.30,80,TRUE),
('Yogurt Cup','dairy',1.10,150,TRUE),
('Trail Mix','snack',1.50,210,TRUE),
('Protein Shake','drink',2.75,180,TRUE),
('Sandwich','meal',3.50,420,TRUE),
('Salad','meal',3.25,260,TRUE);

INSERT INTO Stock VALUES
(1,1,25),(1,2,40),(1,3,30),(1,4,10),(1,5,12),(1,6,6),(1,7,5),(1,8,4),
(2,1,20),(2,2,35),(2,3,15),(2,4,12),(2,5,10),(2,6,4),(2,7,3),(2,8,6),
(3,1,10),(3,2,20),(3,3,12),(3,4,5);

INSERT INTO Restock (staff_id, machine_id, ts) VALUES
(1,1, CURRENT_DATE - INTERVAL '3 days'),
(2,2, CURRENT_DATE - INTERVAL '2 days'),
(2,2, CURRENT_DATE - INTERVAL '1 day');

INSERT INTO RestockLine VALUES
(1,1,15),(1,2,20),(1,7,5),
(2,4,10),(2,8,5),
(3,5,8),(3,6,6);

INSERT INTO Dispense (customer_id, machine_id, item_id, ts, price_charged, payment_method) VALUES
(1,1,1, CURRENT_TIMESTAMP - INTERVAL '6 days 2 hours', 0.75,'card'),
(1,1,2, CURRENT_TIMESTAMP - INTERVAL '6 days 2 hours', 0.00,'voucher'),
(2,2,8, CURRENT_TIMESTAMP - INTERVAL '5 days 5 hours', 3.25,'card'),
(3,1,3, CURRENT_TIMESTAMP - INTERVAL '4 days 1 hour', 0.30,'card'),
(3,1,1, CURRENT_TIMESTAMP - INTERVAL '4 days 1 hour', 0.75,'card'),
(4,2,5, CURRENT_TIMESTAMP - INTERVAL '3 days 3 hours', 1.50,'card'),
(2,2,2, CURRENT_TIMESTAMP - INTERVAL '2 days 6 hours', 0.00,NULL),
(1,1,7, CURRENT_TIMESTAMP - INTERVAL '1 day 4 hours', 3.50,'card'),
(4,1,6, CURRENT_TIMESTAMP - INTERVAL '22 hours', 2.75,'card'),
(2,2,1, CURRENT_TIMESTAMP - INTERVAL '3 hours', 0.75,'card');

-- Multitable Queries
SELECT c.name AS customer, i.name AS item, d.price_charged, d.ts
FROM dispense d
JOIN customer c ON d.customer_id = c.customer_id
JOIN item i     ON d.item_id = i.item_id
WHERE d.price_charged > 3.00
ORDER BY d.ts DESC;

SELECT m.machine_id, m.location, i.name AS item, s.qty
FROM stock s
JOIN machine m ON s.machine_id = m.machine_id
JOIN item i    ON s.item_id = i.item_id
WHERE s.qty < 5
ORDER BY m.location, i.name;

SELECT i.name AS item, m.location
FROM stock s
JOIN machine m ON m.machine_id = s.machine_id
JOIN item i    ON i.item_id = s.item_id
WHERE i.name = 'Granola Bar'
ORDER BY m.location;