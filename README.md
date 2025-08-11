# Grab & Go Vending Machine Database

## 📌 Project Overview
This project is a vending machine backend system called **Grab & Go**.  
It was developed as part of the **CS4092 – Database Design and Development** course.  
The system manages vending machines, customers, items, stock levels, sales (dispenses), and restocking events.

The goal is to demonstrate:
- Database design from requirements gathering to implementation.
- SQL querying and relational schema creation.
- Application-level interaction with the database using Python.

---

## 📂 Project Structure
```
CS4092-grab-go-vending/
│── db.sql # Database schema & seed data
│── queries.sql # Example SQL queries
│── app/
│ ├── main.py # Python CLI application
│── ER_Diagram.png # ER diagram image
│── requirements.pdf # Requirements & use cases document
│── README.md # Project documentation
```


---

## 🗄 Database Design

### **Entities**
- **Customer** – Stores customer details and eligibility type.
- **Staff** – Stores staff/admin info and role.
- **Machine** – Locations and status of vending machines.
- **Item** – List of items for sale, categories, prices, and nutritional info.
- **Stock** – Tracks quantities of each item in each machine.
- **Dispense** – Records each purchase.
- **Restock** – Records restocking events.
- **RestockLine** – Details of which items were added during restocking.

---

## ⚙️ Installation & Setup

### **1. Install PostgreSQL**
Make sure PostgreSQL is installed and running on your system.

Start PostgreSQL:
```bash
brew services start postgresql@14
```

### **2. Create and Seed the Database**
From the project folder, run:
```
dropdb grabgo_db --if-exists
createdb grabgo_db
psql -d grabgo_db -f db.sql
```

### **3. Run SQL Queries Manually**
Example:
```
psql -d grabgo_db
SELECT name, category, unit_cost
FROM Item
WHERE is_active = TRUE;
```

### **4.Run the Python CLI Application**
Make sure you have psycopg2 installed:
```
pip install psycopg2
```
Run the app:
```
python app/main.py
```
