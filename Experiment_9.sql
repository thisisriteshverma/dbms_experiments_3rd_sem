-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL 8.0+

-- EXPERIMENT 9: Railway Booking Indexes
-- AIM: Generate 5,000 railway bookings and compare table scan,
-- single-column index and composite index query plans.

CREATE DATABASE IF NOT EXISTS PerfLab;
USE PerfLab;

-- Number generator: 0-9 digits and integers 1-10000.
CREATE TABLE IF NOT EXISTS Digit (d INT PRIMARY KEY);
INSERT IGNORE INTO Digit VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);
CREATE TABLE IF NOT EXISTS Numbers (n INT PRIMARY KEY);
INSERT IGNORE INTO Numbers (n)
SELECT 1 + a.d + 10*b.d + 100*c.d + 1000*d.d
FROM Digit AS a
CROSS JOIN Digit AS b
CROSS JOIN Digit AS c
CROSS JOIN Digit AS d;

DROP TABLE IF EXISTS RailwayBooking;
CREATE TABLE RailwayBooking (
    booking_id INT PRIMARY KEY,
    train_no INT NOT NULL,
    journey_date DATE NOT NULL,
    passenger_name VARCHAR(40) NOT NULL,
    source VARCHAR(20) NOT NULL,
    destination VARCHAR(20) NOT NULL,
    status VARCHAR(12) NOT NULL,
    fare INT NOT NULL
) ENGINE=InnoDB;

-- Generate exactly 5,000 deterministic bookings.
INSERT INTO RailwayBooking
    (booking_id, train_no, journey_date, passenger_name,
     source, destination, status, fare)
SELECT n,
       12000 + MOD(n, 50),
       DATE_ADD('2026-01-01', INTERVAL MOD(n*17,180) DAY),
       CONCAT('Passenger ', n),
       ELT(1+MOD(n,5),'Delhi','Mumbai','Kolkata','Chennai','Pune'),
       ELT(1+MOD(n,5),'Jaipur','Surat','Patna','Madurai','Nagpur'),
       ELT(1+MOD(n,3),'CONFIRMED','WAITLIST','CANCELLED'),
       300 + MOD(n,1200)
FROM Numbers
WHERE n <= 5000;

SELECT COUNT(*) AS total_bookings FROM RailwayBooking;

-- Query under test (same query for all three configurations).
SELECT booking_id, journey_date, fare
FROM RailwayBooking
WHERE train_no = 12007
  AND journey_date >= '2026-03-01'
  AND journey_date < '2026-04-01'
ORDER BY journey_date, booking_id;

-- 1. Baseline: no secondary index. Inspect the plan.
EXPLAIN FORMAT=TRADITIONAL
SELECT booking_id, journey_date, fare
FROM RailwayBooking
WHERE train_no = 12007
  AND journey_date >= '2026-03-01'
  AND journey_date < '2026-04-01'
ORDER BY journey_date, booking_id;

-- 2. Single-column index on train_no.
CREATE INDEX idx_train ON RailwayBooking(train_no);
ANALYZE TABLE RailwayBooking;
EXPLAIN FORMAT=TRADITIONAL
SELECT booking_id, journey_date, fare
FROM RailwayBooking
WHERE train_no = 12007
  AND journey_date >= '2026-03-01'
  AND journey_date < '2026-04-01'
ORDER BY journey_date, booking_id;
SELECT booking_id, journey_date, fare
FROM RailwayBooking
WHERE train_no = 12007
  AND journey_date >= '2026-03-01'
  AND journey_date < '2026-04-01'
ORDER BY journey_date, booking_id;

-- 3. Replace the single-column index with a composite index.
DROP INDEX idx_train ON RailwayBooking;
CREATE INDEX idx_train_date
    ON RailwayBooking(train_no, journey_date, booking_id);
ANALYZE TABLE RailwayBooking;
EXPLAIN FORMAT=TRADITIONAL
SELECT booking_id, journey_date, fare
FROM RailwayBooking
WHERE train_no = 12007
  AND journey_date >= '2026-03-01'
  AND journey_date < '2026-04-01'
ORDER BY journey_date, booking_id;
SELECT booking_id, journey_date, fare
FROM RailwayBooking
WHERE train_no = 12007
  AND journey_date >= '2026-03-01'
  AND journey_date < '2026-04-01'
ORDER BY journey_date, booking_id;

-- Optional MySQL 8.0.18+ actual execution analysis:
-- EXPLAIN ANALYZE SELECT booking_id, journey_date, fare
-- FROM RailwayBooking
-- WHERE train_no=12007
--   AND journey_date>='2026-03-01' AND journey_date<'2026-04-01'
-- ORDER BY journey_date, booking_id;

-- Notes: the PDF's measured timings and plan transcripts were produced
-- with SQLite, not MySQL. Do not treat those timings as MySQL measurements.
-- In the reported local run, all plans returned 22 rows; composite index
-- median was 0.0158 ms versus 0.1364 ms baseline (SQLite measurement).

-- RESULT: The composite index supports train equality, date range filtering
-- and ordering. Indexes use storage and add INSERT/UPDATE maintenance cost.
