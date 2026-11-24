-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL 8.0+

-- EXPERIMENT 8: Transactions and Concurrency
-- AIM: Demonstrate atomic transfers, rollback, savepoints and isolation levels.
-- IMPORTANT: Run the two-session demonstrations manually in TWO MySQL
-- connections. The schedules below are illustrative InnoDB exercises.

CREATE DATABASE IF NOT EXISTS BankLab;
USE BankLab;

DROP TABLE IF EXISTS Account;
CREATE TABLE Account (
    account_id INT PRIMARY KEY,
    balance DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_account_balance CHECK (balance >= 0)
) ENGINE=InnoDB;

INSERT INTO Account (account_id, balance)
VALUES (1, 10000.00), (2, 5000.00);

-- 1. Successful atomic transfer: account 1 sends 1000 to account 2.
START TRANSACTION;
SELECT * FROM Account
WHERE account_id IN (1, 2)
ORDER BY account_id
FOR UPDATE;

UPDATE Account SET balance = balance - 1000 WHERE account_id = 1;
UPDATE Account SET balance = balance + 1000 WHERE account_id = 2;
COMMIT;
SELECT * FROM Account ORDER BY account_id;
-- Expected: account 1 = 9000; account 2 = 6000; total = 15000.

-- 2. Partial failure: destination account 999 does not exist.
-- ROW_COUNT() returns 0; zero affected rows is not itself an SQL exception.
START TRANSACTION;
UPDATE Account SET balance = balance - 700 WHERE account_id = 1;
UPDATE Account SET balance = balance + 700 WHERE account_id = 999;
SELECT ROW_COUNT() AS affected_destination_rows;
ROLLBACK;
SELECT * FROM Account ORDER BY account_id;
-- Expected balances remain 9000 and 6000.

-- 3. SAVEPOINT: keep the transfer but undo the optional fee step.
START TRANSACTION;
UPDATE Account SET balance = balance - 500 WHERE account_id = 1;
UPDATE Account SET balance = balance + 500 WHERE account_id = 2;
SAVEPOINT fee_step;
UPDATE Account SET balance = balance - 50 WHERE account_id = 1;
-- Simulated fee-service rejection: undo only the fee operation.
ROLLBACK TO SAVEPOINT fee_step;
RELEASE SAVEPOINT fee_step;
COMMIT;
SELECT * FROM Account ORDER BY account_id;
-- Expected: account 1 = 8500; account 2 = 6500.

-- 4. Constraint failure demonstration.
-- Expected MySQL 8.0.16+: CHECK constraint violation. Execute the UPDATE
-- separately, then issue ROLLBACK in the same session after the error.
START TRANSACTION;
UPDATE Account SET balance = balance - 20000 WHERE account_id = 1;
ROLLBACK;
SELECT * FROM Account ORDER BY account_id;

-- 5. TWO-SESSION ISOLATION EXERCISES
-- Before each exercise, finish open transactions and reset balances:
-- UPDATE Account SET balance=10000 WHERE account_id=1;
-- UPDATE Account SET balance=5000 WHERE account_id=2;
-- COMMIT;

-- DIRTY READ: READ UNCOMMITTED
-- Session A:
-- START TRANSACTION;
-- UPDATE Account SET balance=9000 WHERE account_id=1;
-- Session B:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
-- SELECT balance FROM Account WHERE account_id=1; -- may show 9000
-- Session A:
-- ROLLBACK;
-- Session B:
-- SELECT balance FROM Account WHERE account_id=1; -- now 10000
-- COMMIT;

-- NON-REPEATABLE READ: READ COMMITTED
-- Session B:
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
-- SELECT balance FROM Account WHERE account_id=1; -- 10000
-- Session A:
-- START TRANSACTION;
-- UPDATE Account SET balance=9000 WHERE account_id=1;
-- COMMIT;
-- Session B:
-- SELECT balance FROM Account WHERE account_id=1; -- 9000
-- COMMIT;

-- REPEATABLE READ SNAPSHOT
-- Reset account 1 to 10000 and COMMIT before this test.
-- Session B:
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- START TRANSACTION;
-- SELECT balance FROM Account WHERE account_id=1; -- 10000
-- Session A:
-- START TRANSACTION;
-- UPDATE Account SET balance=9000 WHERE account_id=1;
-- COMMIT;
-- Session B:
-- SELECT balance FROM Account WHERE account_id=1; -- remains 10000 in snapshot
-- COMMIT;
-- SELECT balance FROM Account WHERE account_id=1; -- new transaction sees 9000

-- PHANTOM READ exercise
-- Reset to exactly two accounts. Session B (READ COMMITTED):
-- START TRANSACTION;
-- SELECT COUNT(*) FROM Account WHERE balance >= 5000; -- 2
-- Session A:
-- INSERT INTO Account VALUES (3,7000);
-- COMMIT;
-- Session B:
-- SELECT COUNT(*) FROM Account WHERE balance >= 5000; -- 3
-- COMMIT;
-- Repeat under REPEATABLE READ after deleting account 3 and committing;
-- two plain consistent reads in B use the same snapshot.

-- SERIALIZABLE blocking exercise
-- Session B:
-- SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- START TRANSACTION;
-- SELECT balance FROM Account WHERE account_id=1;
-- Session A (UPDATE waits while B holds its read lock):
-- START TRANSACTION;
-- UPDATE Account SET balance=9000 WHERE account_id=1;
-- Session B:
-- COMMIT;
-- Session A: UPDATE completes, then COMMIT;

-- LOST UPDATE demonstration (unsafe absolute writes)
-- Reset account 1 to 10000 and commit.
-- Session A and Session B both read 10000 in separate transactions.
-- A writes 9000 and commits; B writes stale computed value 9500 and commits.
-- Final 9500 loses A's deduction; correct combined balance would be 8500.
-- Safe relative update pattern:
-- START TRANSACTION;
-- UPDATE Account SET balance=balance-1000
-- WHERE account_id=1 AND balance>=1000;
-- SELECT ROW_COUNT(); -- application must require exactly 1
-- COMMIT;
-- Alternatively, SELECT ... FOR UPDATE before calculating a new balance.

-- Isolation summary:
-- READ UNCOMMITTED: dirty reads possible; repeated reads may change.
-- READ COMMITTED: dirty reads prevented; repeated reads may change.
-- REPEATABLE READ: dirty reads prevented; consistent reads use a stable snapshot.
-- SERIALIZABLE: dirty reads prevented; conflicting reads/writes may block.

-- RESULT: COMMIT, ROLLBACK and SAVEPOINT demonstrate transaction control.
-- The two-session schedules explain dirty reads, non-repeatable reads,
-- phantoms, lost updates and blocking. Run them manually in two sessions.
