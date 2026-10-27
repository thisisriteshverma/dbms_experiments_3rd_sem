-- EXPERIMENT 5: SQL Views, Updatability, and Recursive CTE
-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL
-- This script uses the company_db database and Employee table from earlier experiments.

USE company_db;

-- 1. Add manager_id column if it does not already exist.
-- If manager_id already exists from a previous run, skip this ALTER statement.
ALTER TABLE Employee
ADD COLUMN manager_id INT NULL;

-- 2. Add a self-referencing foreign key for employee-manager relationship.
-- Run only once; skip if this constraint already exists.
ALTER TABLE Employee
ADD CONSTRAINT fk_employee_manager
FOREIGN KEY (manager_id) REFERENCES Employee(emp_id);

-- 3. Set up employee hierarchy (top-level employees have NULL manager_id).
UPDATE Employee SET manager_id = NULL WHERE emp_id IN (1, 7, 13, 19, 25);

-- IT hierarchy
UPDATE Employee SET manager_id = 1 WHERE emp_id IN (2, 3, 5);
UPDATE Employee SET manager_id = 2 WHERE emp_id IN (4, 6);

-- HR hierarchy
UPDATE Employee SET manager_id = 7 WHERE emp_id IN (8, 9, 10);
UPDATE Employee SET manager_id = 8 WHERE emp_id IN (11, 12);

-- Finance hierarchy
UPDATE Employee SET manager_id = 13 WHERE emp_id IN (14, 15, 16);
UPDATE Employee SET manager_id = 14 WHERE emp_id IN (17, 18);

-- Marketing hierarchy
UPDATE Employee SET manager_id = 19 WHERE emp_id IN (20, 21, 22);
UPDATE Employee SET manager_id = 20 WHERE emp_id IN (23, 24);

-- Operations hierarchy
UPDATE Employee SET manager_id = 25 WHERE emp_id IN (26, 27, 28);
UPDATE Employee SET manager_id = 26 WHERE emp_id IN (29, 30);

-- 4. Department salary summary view
CREATE OR REPLACE VIEW department_salary_summary AS
SELECT
    d.dept_id,
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary,
    MIN(e.salary) AS minimum_salary,
    MAX(e.salary) AS maximum_salary
FROM Department d
LEFT JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Display department salary summary
SELECT * FROM department_salary_summary;

-- 5. Employee hierarchy view using a self-join
CREATE OR REPLACE VIEW employee_hierarchy AS
SELECT
    e.emp_id,
    e.emp_name AS employee_name,
    e.salary,
    e.dept_id,
    e.manager_id,
    m.emp_name AS manager_name
FROM Employee e
LEFT JOIN Employee m ON e.manager_id = m.emp_id;

-- Display employee hierarchy
SELECT * FROM employee_hierarchy;

-- 6. Test updatability of employee hierarchy view.
-- This self-join view is not treated as a simple updatable view.
-- Depending on MySQL's view rules, UPDATE may be rejected.
-- If it is rejected, that is the expected demonstration for this experiment.
-- UPDATE employee_hierarchy SET salary = salary + 1000 WHERE emp_id = 2;

-- 7. Create a simple employee salary view (single-table view)
CREATE OR REPLACE VIEW employee_salary_view AS
SELECT emp_id, emp_name, salary
FROM Employee;

-- Update through the simple view (should update the underlying Employee row)
UPDATE employee_salary_view
SET salary = salary + 1000
WHERE emp_id = 2;

-- Verify the update
SELECT emp_id, emp_name, salary
FROM employee_salary_view
WHERE emp_id = 2;

-- 8. Test that aggregate view is not directly updatable.
-- This is intentionally commented because it normally fails in MySQL:
