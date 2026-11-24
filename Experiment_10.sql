-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL 8.0+

-- EXPERIMENT 10: Query Optimization
-- AIM: Create 10,000 orders, inspect five slow queries and optimize them
-- using indexes and equivalent query rewrites.
-- This script is standalone: it creates PerfLab and its number generator.

CREATE DATABASE IF NOT EXISTS PerfLab;
USE PerfLab;

CREATE TABLE IF NOT EXISTS Digit (d INT PRIMARY KEY);
INSERT IGNORE INTO Digit VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);
CREATE TABLE IF NOT EXISTS Numbers (n INT PRIMARY KEY);
INSERT IGNORE INTO Numbers (n)
SELECT 1 + a.d + 10*b.d + 100*c.d + 1000*d.d
FROM Digit AS a
CROSS JOIN Digit AS b
CROSS JOIN Digit AS c
CROSS JOIN Digit AS d;

DROP TABLE IF EXISTS OrdersBench;
DROP TABLE IF EXISTS Customers;
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(40) NOT NULL
) ENGINE=InnoDB;
INSERT INTO Customers
SELECT n, CONCAT('Customer ', n)
FROM Numbers WHERE n <= 1000;

CREATE TABLE OrdersBench (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(12) NOT NULL,
    amount_cents INT NOT NULL,
    email VARCHAR(80) NOT NULL
) ENGINE=InnoDB;

INSERT INTO OrdersBench
    (order_id, customer_id, order_date, status, amount_cents, email)
SELECT n,
       1 + MOD(n,1000),
       DATE_ADD('2026-01-01', INTERVAL MOD(n*13,365) DAY),
       ELT(1+MOD(n,3),'PAID','PENDING','CANCELLED'),
       1000 + MOD(n*97,99000),
       CONCAT('user',MOD(n,1000),'@example.com')
FROM Numbers;

SELECT COUNT(*) AS order_count FROM OrdersBench; -- 10000
SELECT COUNT(*) AS customer_count FROM Customers; -- 1000

-- Q1. Date function prevents a straightforward index range lookup.
-- BEFORE:
EXPLAIN FORMAT=TRADITIONAL
SELECT COUNT(*) FROM OrdersBench
WHERE DATE_FORMAT(order_date,'%Y-%m') = '2026-03';
SELECT COUNT(*) FROM OrdersBench
WHERE DATE_FORMAT(order_date,'%Y-%m') = '2026-03';

-- AFTER: use a half-open date range and an index.
CREATE INDEX idx_date ON OrdersBench(order_date);
ANALYZE TABLE OrdersBench;
EXPLAIN FORMAT=TRADITIONAL
SELECT COUNT(*) FROM OrdersBench
WHERE order_date >= '2026-03-01' AND order_date < '2026-04-01';
SELECT COUNT(*) FROM OrdersBench
WHERE order_date >= '2026-03-01' AND order_date < '2026-04-01';
DROP INDEX idx_date ON OrdersBench;

-- Q2. Composite index for customer equality and amount range.
-- BEFORE:
EXPLAIN FORMAT=TRADITIONAL
SELECT order_id, amount_cents FROM OrdersBench
WHERE customer_id=42 AND amount_cents>=50000
ORDER BY order_id;
SELECT order_id, amount_cents FROM OrdersBench
WHERE customer_id=42 AND amount_cents>=50000
ORDER BY order_id;

-- AFTER:
CREATE INDEX idx_customer_amount
    ON OrdersBench(customer_id, amount_cents);
ANALYZE TABLE OrdersBench;
EXPLAIN FORMAT=TRADITIONAL
SELECT order_id, amount_cents FROM OrdersBench
WHERE customer_id=42 AND amount_cents>=50000
ORDER BY order_id;
SELECT order_id, amount_cents FROM OrdersBench
WHERE customer_id=42 AND amount_cents>=50000
ORDER BY order_id;
DROP INDEX idx_customer_amount ON OrdersBench;

-- Q3. Index the status filter and descending date/order sequence.
-- BEFORE:
EXPLAIN FORMAT=TRADITIONAL
SELECT order_id, order_date FROM OrdersBench
WHERE status='PAID'
ORDER BY order_date DESC, order_id DESC LIMIT 20;
SELECT order_id, order_date FROM OrdersBench
WHERE status='PAID'
ORDER BY order_date DESC, order_id DESC LIMIT 20;

-- AFTER:
CREATE INDEX idx_status_date
    ON OrdersBench(status, order_date DESC, order_id DESC);
ANALYZE TABLE OrdersBench;
EXPLAIN FORMAT=TRADITIONAL
SELECT order_id, order_date FROM OrdersBench
WHERE status='PAID'
ORDER BY order_date DESC, order_id DESC LIMIT 20;
SELECT order_id, order_date FROM OrdersBench
WHERE status='PAID'
ORDER BY order_date DESC, order_id DESC LIMIT 20;
DROP INDEX idx_status_date ON OrdersBench;

-- Q4. Replace repeated correlated aggregation with one grouped aggregation.
-- BEFORE:
EXPLAIN FORMAT=TRADITIONAL
SELECT c.customer_id,
       (SELECT SUM(o.amount_cents)
        FROM OrdersBench AS o
        WHERE o.customer_id=c.customer_id) AS total
FROM Customers AS c
ORDER BY c.customer_id;
SELECT c.customer_id,
       (SELECT SUM(o.amount_cents)
        FROM OrdersBench AS o
        WHERE o.customer_id=c.customer_id) AS total
FROM Customers AS c
ORDER BY c.customer_id;

-- AFTER: pre-aggregate once, then LEFT JOIN to retain customers without orders.
CREATE INDEX idx_customer_amount
    ON OrdersBench(customer_id, amount_cents);
ANALYZE TABLE OrdersBench;
EXPLAIN FORMAT=TRADITIONAL
SELECT c.customer_id, a.total
FROM Customers AS c
LEFT JOIN (
    SELECT customer_id, SUM(amount_cents) AS total
    FROM OrdersBench
    GROUP BY customer_id
) AS a ON a.customer_id=c.customer_id
ORDER BY c.customer_id;
SELECT c.customer_id, a.total
FROM Customers AS c
LEFT JOIN (
    SELECT customer_id, SUM(amount_cents) AS total
    FROM OrdersBench
    GROUP BY customer_id
) AS a ON a.customer_id=c.customer_id
ORDER BY c.customer_id;
DROP INDEX idx_customer_amount ON OrdersBench;

-- Q5. Generated email values are already lowercase, so LOWER() is unnecessary.
-- For arbitrary mixed-case data, normalize on write or use a suitable
-- functional index/collation instead.
-- BEFORE:
EXPLAIN FORMAT=TRADITIONAL
SELECT order_id FROM OrdersBench
WHERE LOWER(email)='user41@example.com'
ORDER BY order_id;
SELECT order_id FROM OrdersBench
WHERE LOWER(email)='user41@example.com'
ORDER BY order_id;

-- AFTER:
CREATE INDEX idx_email ON OrdersBench(email);
ANALYZE TABLE OrdersBench;
EXPLAIN FORMAT=TRADITIONAL
SELECT order_id FROM OrdersBench
WHERE email='user41@example.com'
ORDER BY order_id;
SELECT order_id FROM OrdersBench
WHERE email='user41@example.com'
ORDER BY order_id;

-- Optional actual execution plans (MySQL 8.0.18+):
-- EXPLAIN ANALYZE SELECT ...;

-- Benchmark note: the PDF's reported timings are SQLite measurements,
-- not estimated or measured MySQL runtimes. Re-run each query several times
-- on your MySQL server and compare median timings and complete result sets.
-- The report recorded these local SQLite speedups: Q1 114.85x, Q2 84.32x,
-- Q3 81.54x, Q4 10.70x, Q5 297.94x.

-- RESULT: The five query pairs are designed to return equivalent results.
-- Indexes make predicates searchable; rewrites reduce repeated work.
