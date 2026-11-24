-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL 8.0+

-- EXPERIMENT 7: Normalization and Verification (UNF to BCNF)
-- AIM: Identify functional dependencies and normalize a sales relation.
-- The script builds a 1NF source table, decomposes it into five relations,
-- populates them, reconstructs the source and verifies lossless join.

CREATE DATABASE IF NOT EXISTS NormalizationLab;
USE NormalizationLab;

-- Clean objects so the experiment can be run again.
DROP VIEW IF EXISTS Reconstructed;
DROP TABLE IF EXISTS OrderLine;
DROP TABLE IF EXISTS SalesOrder;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Sales1NF;

-- Functional dependencies:
-- order_id -> order_date, customer_id
-- customer_id -> customer_name, city
-- product_id -> product_name, category_id
-- category_id -> category_name
-- (order_id, product_id) -> qty, unit_price
-- Candidate key: (order_id, product_id)

-- 1. UNF to 1NF: one atomic product per order row.
CREATE TABLE Sales1NF (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL,
    customer_name VARCHAR(40) NOT NULL,
    city VARCHAR(30) NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(40) NOT NULL,
    category_id INT NOT NULL,
    category_name VARCHAR(30) NOT NULL,
    qty INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
) ENGINE=InnoDB;

INSERT INTO Sales1NF VALUES
(101,'2026-01-10',1,'Asha','Delhi',10,'Keyboard',1,'Accessories',2,800.00),
(101,'2026-01-10',1,'Asha','Delhi',20,'Monitor',2,'Displays',1,9000.00),
(102,'2026-01-11',2,'Ravi','Pune',10,'Keyboard',1,'Accessories',1,750.00),
(103,'2026-01-12',1,'Asha','Delhi',30,'Mouse',1,'Accessories',3,400.00),
(104,'2026-01-13',3,'Neha','Jaipur',20,'Monitor',2,'Displays',2,8800.00),
(104,'2026-01-13',3,'Neha','Jaipur',30,'Mouse',1,'Accessories',1,380.00);

-- 2. 2NF to 3NF: remove partial and transitive dependencies.
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(40) NOT NULL,
    city VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(40) NOT NULL,
    category_id INT NOT NULL,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
        REFERENCES Category(category_id)
) ENGINE=InnoDB;

CREATE TABLE SalesOrder (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES Customer(customer_id)
) ENGINE=InnoDB;

CREATE TABLE OrderLine (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    qty INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT fk_line_order FOREIGN KEY (order_id)
        REFERENCES SalesOrder(order_id),
    CONSTRAINT fk_line_product FOREIGN KEY (product_id)
        REFERENCES Product(product_id)
) ENGINE=InnoDB;

-- 3. Populate normalized relations from the 1NF source.
INSERT INTO Customer
SELECT DISTINCT customer_id, customer_name, city FROM Sales1NF;

INSERT INTO Category
SELECT DISTINCT category_id, category_name FROM Sales1NF;

INSERT INTO Product
SELECT DISTINCT product_id, product_name, category_id FROM Sales1NF;

INSERT INTO SalesOrder
SELECT DISTINCT order_id, order_date, customer_id FROM Sales1NF;

INSERT INTO OrderLine
SELECT order_id, product_id, qty, unit_price FROM Sales1NF;

-- 4. Reconstruct the original relation (lossless join check).
CREATE VIEW Reconstructed AS
SELECT o.order_id, o.order_date, c.customer_id, c.customer_name, c.city,
       p.product_id, p.product_name, k.category_id, k.category_name,
       l.qty, l.unit_price
FROM OrderLine AS l
JOIN SalesOrder AS o ON o.order_id = l.order_id
JOIN Customer AS c ON c.customer_id = o.customer_id
JOIN Product AS p ON p.product_id = l.product_id
JOIN Category AS k ON k.category_id = p.category_id;

-- 5. Compare row counts.
SELECT COUNT(*) AS source_rows FROM Sales1NF;
SELECT COUNT(*) AS reconstructed_rows FROM Reconstructed;

-- 6. Rows missing from reconstructed relation (expected: 0).
SELECT COUNT(*) AS missing_rows
FROM Sales1NF AS s
WHERE NOT EXISTS (
    SELECT 1 FROM Reconstructed AS r
    WHERE r.order_id = s.order_id
      AND r.product_id = s.product_id
      AND r.order_date = s.order_date
      AND r.customer_id = s.customer_id
      AND r.customer_name = s.customer_name
      AND r.city = s.city
      AND r.product_name = s.product_name
      AND r.category_id = s.category_id
      AND r.category_name = s.category_name
      AND r.qty = s.qty
      AND r.unit_price = s.unit_price
);

-- 7. Extra rows in reconstructed relation (expected: 0).
SELECT COUNT(*) AS extra_rows
FROM Reconstructed AS r
WHERE NOT EXISTS (
    SELECT 1 FROM Sales1NF AS s
    WHERE s.order_id = r.order_id
      AND s.product_id = r.product_id
      AND s.order_date = r.order_date
      AND s.customer_id = r.customer_id
      AND s.customer_name = r.customer_name
      AND s.city = r.city
      AND s.product_name = r.product_name
      AND s.category_id = r.category_id
      AND s.category_name = r.category_name
      AND s.qty = r.qty
      AND s.unit_price = r.unit_price
);

-- 8. Verify the functional dependencies against the fixture.
-- Each query should return zero rows.
SELECT order_id FROM Sales1NF GROUP BY order_id
HAVING COUNT(DISTINCT order_date) > 1 OR COUNT(DISTINCT customer_id) > 1;

SELECT customer_id FROM Sales1NF GROUP BY customer_id
HAVING COUNT(DISTINCT customer_name) > 1 OR COUNT(DISTINCT city) > 1;

SELECT product_id FROM Sales1NF GROUP BY product_id
HAVING COUNT(DISTINCT product_name) > 1 OR COUNT(DISTINCT category_id) > 1;

SELECT category_id FROM Sales1NF GROUP BY category_id
HAVING COUNT(DISTINCT category_name) > 1;

SELECT order_id, product_id FROM Sales1NF
GROUP BY order_id, product_id
HAVING COUNT(DISTINCT qty) > 1 OR COUNT(DISTINCT unit_price) > 1;

-- Expected fixture checks: 6 source rows, 6 reconstructed rows,
-- 0 missing rows, 0 extra rows; SUM(qty * unit_price) = 30530.00.
SELECT SUM(qty * unit_price) AS total_sales_value FROM Sales1NF;

-- RESULT: The five-table decomposition is lossless and dependency-preserving
-- and satisfies BCNF under the functional dependencies stated above.
