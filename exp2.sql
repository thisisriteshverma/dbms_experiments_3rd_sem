-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL

-- EXPERIMENT 2
-- TITLE: ER-to-Relational Mapping and Referential Integrity

-- 1. CREATE DATABASE

CREATE DATABASE IF NOT EXISTS IndianShop;
USE IndianShop;


-- 2. CUSTOMER AND CUSTOMER PHONE

CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(40) NOT NULL,
    last_name VARCHAR(40) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE CustomerPhone (
    customer_id INT NOT NULL,
    phone VARCHAR(16) NOT NULL,
    PRIMARY KEY (customer_id, phone),
    FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- 3. ADDRESS AND SELLER

CREATE TABLE Address (
    address_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    street VARCHAR(120) NOT NULL,
    city VARCHAR(40) NOT NULL,
    state VARCHAR(40) NOT NULL,
    pincode CHAR(6) NOT NULL,

    UNIQUE (address_id, customer_id),

    FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE Seller (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(80) NOT NULL,
    gstin CHAR(15) NOT NULL UNIQUE
) ENGINE=InnoDB;


-- 4. CATEGORY AND PRODUCT

CREATE TABLE Category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    seller_id INT NOT NULL,
    category_id INT NULL,
    title VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),

    product_type VARCHAR(12) NOT NULL,
    warranty_months INT NULL,
    size_label VARCHAR(10) NULL,
    fabric VARCHAR(30) NULL,

    CHECK (
        (
            product_type = 'Electronics'
            AND warranty_months IS NOT NULL
            AND warranty_months >= 0
            AND size_label IS NULL
            AND fabric IS NULL
        )
        OR
        (
            product_type = 'Clothing'
            AND warranty_months IS NULL
            AND size_label IS NOT NULL
            AND fabric IS NOT NULL
        )
    ),

    FOREIGN KEY (seller_id)
        REFERENCES Seller(seller_id)
        ON DELETE RESTRICT,

    FOREIGN KEY (category_id)
        REFERENCES Category(category_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;


-- 5. CUSTOMER ORDER AND ORDER ITEMS

CREATE TABLE CustomerOrder (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    address_id INT NOT NULL,
    placed_at DATETIME NOT NULL,

    FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id)
        ON DELETE RESTRICT,

    FOREIGN KEY (address_id, customer_id)
        REFERENCES Address(address_id, customer_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE OrderItem (
    order_id INT NOT NULL,
    line_no INT NOT NULL CHECK (line_no > 0),
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),

    PRIMARY KEY (order_id, line_no),

    FOREIGN KEY (order_id)
        REFERENCES CustomerOrder(order_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES Product(product_id)
        ON DELETE RESTRICT
) ENGINE=InnoDB;


-- 6. PAYMENT AND DELIVERY

CREATE TABLE Payment (
    payment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    method VARCHAR(10) NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status VARCHAR(12) NOT NULL,
    reference_no VARCHAR(60) NOT NULL UNIQUE,

    CHECK (method IN ('UPI', 'CARD', 'NETBANKING', 'COD')),
    CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED')),

    FOREIGN KEY (order_id)
        REFERENCES CustomerOrder(order_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Delivery (
    delivery_id INT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    tracking_no VARCHAR(40) NOT NULL UNIQUE,
    status VARCHAR(12) NOT NULL,

    CHECK (status IN ('PENDING', 'SHIPPED', 'DELIVERED')),

    FOREIGN KEY (order_id)
        REFERENCES CustomerOrder(order_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- 7. INSERT SAMPLE DATA

INSERT INTO Customer VALUES
(1, 'Asha', 'Sharma', 'asha@example.com'),
(2, 'Ravi', 'Patel', 'ravi@example.com');

INSERT INTO CustomerPhone VALUES
(1, '+919000000001'),
(1, '+919000000002'),
(2, '+919000000003');

INSERT INTO Address VALUES
(11, 1, '12 MG Road', 'Delhi', 'Delhi', '110001'),
(12, 2, '8 FC Road', 'Pune', 'Maharashtra', '411004');

INSERT INTO Seller VALUES
(21, 'Demo Digital', '07ABCDE1234F1Z5'),
(22, 'Demo Fashion', '27ABCDE5678G1Z2');

INSERT INTO Category VALUES
(31, 'Electronics'),
(32, 'Clothing');

INSERT INTO Product VALUES
(101, 21, 31, 'Headphones', 1999, 'Electronics', 12, NULL, NULL),
(102, 22, 32, 'Cotton Kurta', 799, 'Clothing', NULL, 'M', 'Cotton');


-- 8. INSERT ORDERS AND RELATED RECORDS

START TRANSACTION;

INSERT INTO CustomerOrder VALUES
(1001, 1, 11, '2026-10-01 10:00:00'),
(1002, 2, 12, '2026-10-02 11:00:00');

INSERT INTO OrderItem VALUES
(1001, 1, 101, 1, 1999),
(1001, 2, 102, 2, 799),
(1002, 1, 102, 1, 799);

INSERT INTO Payment VALUES
(501, 1001, 'UPI', 3597, 'SUCCESS', 'DEMO-UPI-501'),
(502, 1002, 'CARD', 799, 'FAILED', 'DEMO-CARD-502'),
(503, 1002, 'UPI', 799, 'SUCCESS', 'DEMO-UPI-503');

INSERT INTO Delivery VALUES
(601, 1001, 'DEMO-TRACK-601', 'DELIVERED'),
(602, 1002, 'DEMO-TRACK-602', 'SHIPPED');

COMMIT;


-- 9. DISPLAY ORDER DETAILS AND TOTAL AMOUNT

SELECT
    o.order_id,
    c.first_name,
    SUM(i.quantity * i.unit_price) AS total_inr
FROM CustomerOrder o
JOIN Customer c
    ON c.customer_id = o.customer_id
JOIN OrderItem i
    ON i.order_id = o.order_id
GROUP BY o.order_id, c.first_name
ORDER BY o.order_id;


-- 10. DISPLAY CUSTOMER PHONE NUMBERS

SELECT customer_id, phone
FROM CustomerPhone
ORDER BY customer_id, phone;


-- 11. COUNT PAYMENT ATTEMPTS FOR EACH ORDER

SELECT
    order_id,
    COUNT(*) AS attempts
FROM Payment
GROUP BY order_id
ORDER BY order_id;


-- 12. REFERENTIAL INTEGRITY VIOLATIONS
-- Run each invalid statement individually.
-- These statements are expected to fail.

-- Missing parent order: expected error 1452
-- INSERT INTO OrderItem VALUES (9999, 1, 101, 1, 1999);

-- Missing parent product: expected error 1452
-- INSERT INTO OrderItem VALUES (1001, 3, 9999, 1, 100);

-- Address 12 belongs to customer 2, not customer 1.
-- Expected error 1452 on the composite foreign key.
-- INSERT INTO CustomerOrder VALUES
-- (1003, 1, 12, '2026-10-03 09:00:00');

-- Referenced product cannot be deleted: expected error 1451
-- DELETE FROM Product WHERE product_id = 101;

-- Referenced customer cannot be deleted: expected error 1451
-- DELETE FROM Customer WHERE customer_id = 1;


-- 13. ADDITIONAL INTEGRITY TESTS
-- Run each invalid statement individually.

-- Duplicate email: expected error 1062
-- INSERT INTO Customer VALUES
-- (3, 'Neha', 'Das', 'asha@example.com');

-- Invalid quantity: expected CHECK constraint failure
-- INSERT INTO OrderItem VALUES
-- (1001, 3, 101, 0, 1999);

-- Missing required first name: expected error 1048
-- INSERT INTO Customer VALUES
-- (3, NULL, 'Das', 'neha@example.com');


-- 14. DEMONSTRATE SET NULL

START TRANSACTION;

DELETE FROM Category
WHERE category_id = 31;

SELECT product_id, category_id
FROM Product
WHERE product_id = 101;

-- Expected category_id: NULL

ROLLBACK;


-- 15. DEMONSTRATE CASCADE DELETE

START TRANSACTION;

DELETE FROM CustomerOrder
WHERE order_id = 1001;

SELECT COUNT(*) AS order_items
FROM OrderItem
WHERE order_id = 1001;

SELECT COUNT(*) AS payments
FROM Payment
WHERE order_id = 1001;

SELECT COUNT(*) AS deliveries
FROM Delivery
WHERE order_id = 1001;

SELECT COUNT(*) AS remaining_products
FROM Product;

-- Expected:
-- order_items = 0
-- payments = 0
-- deliveries = 0
-- remaining_products = 2

ROLLBACK;


-- 16. VERIFY RESTORED RECORDS

SELECT COUNT(*) AS total_order_items
FROM OrderItem;

SELECT COUNT(*) AS total_payments
FROM Payment;

SELECT COUNT(*) AS total_deliveries
FROM Delivery;

-- Expected:
-- total_order_items = 3
-- total_payments = 3
-- total_deliveries = 2


-- RESULT:
-- The ER design has been mapped into ten relations.
-- Primary keys and unique constraints prevent duplicate records.
-- Foreign keys maintain referential integrity.
-- CHECK constraints enforce valid data and product specialization.
-- CASCADE and SET NULL demonstrate different deletion policies.
