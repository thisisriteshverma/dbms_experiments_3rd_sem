-- EXPERIMENT 4: SQL Joins, Subqueries, Set Operations, and EXPLAIN
-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL
-- This experiment uses the company_db schema from Experiment 3.

USE company_db;

-- 1. INNER JOIN: display employees with their department names
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    e.salary
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id;

-- 2. LEFT JOIN: display all departments and their employees, including departments
-- with no matching employee
SELECT
    d.dept_id,
    d.dept_name,
    e.emp_name,
    e.salary
FROM Department d
LEFT JOIN Employee e ON d.dept_id = e.dept_id;

-- 3. SELF-JOIN: find pairs of employees working in the same department
SELECT
    e1.emp_name AS Employee1,
    e2.emp_name AS Employee2,
    e1.dept_id
FROM Employee e1
INNER JOIN Employee e2
    ON e1.dept_id = e2.dept_id
   AND e1.emp_id < e2.emp_id;

-- 4. THREE-WAY JOIN: employee, department, and project details
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    p.project_name,
    e.salary
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
INNER JOIN Project p ON e.project_id = p.project_id;

-- 5. CORRELATED SUBQUERY: employees earning more than their department's average
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    e.dept_id
FROM Employee e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e2.dept_id = e.dept_id
);

-- 6. CORRELATED SUBQUERY: highest-paid employee(s) in each department
SELECT
    e.emp_id,
    e.emp_name,
    e.salary,
    e.dept_id
FROM Employee e
WHERE e.salary = (
    SELECT MAX(e2.salary)
    FROM Employee e2
    WHERE e2.dept_id = e.dept_id
);

-- 7. EXISTS: departments with at least one employee
SELECT
    d.dept_id,
    d.dept_name
FROM Department d
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.dept_id = d.dept_id
);

-- 8. EXISTS: employees working on projects with a budget greater than 800000
SELECT
    e.emp_id,
    e.emp_name
FROM Employee e
WHERE EXISTS (
    SELECT 1
    FROM Project p
    WHERE p.project_id = e.project_id
      AND p.budget > 800000
);
