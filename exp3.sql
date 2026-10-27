(10, 'Simran Kaur', 72000, '2020-12-01', 2, 103),
(11, 'Pooja Agarwal', 68000, '2020-10-11', 2, 103),
(12, 'Aditya Jain', 62000, '2022-02-14', 2, 103),
(13, 'Amit Shah', 90000, '2019-05-19', 3, 104),
(14, 'Kavya Rao', 88000, '2020-10-19', 3, 104),
(15, 'Manish Gupta', 76000, '2021-03-25', 3, 104),
(16, 'Isha Patel', 82000, '2020-06-30', 3, 104),
(17, 'Nitin Yadav', 70000, '2022-01-20', 3, 104),
(18, 'Meera Nair', 75000, '2019-11-23', 3, 104),
(19, 'Sakshi Mishra', 65000, '2021-07-12', 4, 105),
(20, 'Arjun Kapoor', 72000, '2020-09-04', 4, 105),
(21, 'Tanya Sethi', 78000, '2022-02-28', 4, 108),
(22, 'Yash Thakur', 60000, '2021-04-15', 4, 108),
(23, 'Riya Bansal', 85000, '2020-09-05', 4, 105),
(24, 'Mohit Arora', 69000, '2022-03-27', 4, 105),
(25, 'Deepak Singh', 70000, '2020-02-15', 5, 106),
(26, 'Nisha Verma', 75000, '2021-05-25', 5, 106),
(27, 'Varun Khanna', 68000, '2022-04-14', 5, 106),
(28, 'Ayesha Khan', 82000, '2019-10-30', 5, 106),
(29, 'Suresh Reddy', 80000, '2021-06-12', 5, 106),
(30, 'Divya Menon', 77000, '2020-03-09', 5, 106);

-- 5. Selection: employees earning more than 80000
SELECT *
FROM Employee
WHERE salary > 80000;

-- 6. Projection: display only employee name and salary
SELECT emp_name, salary
FROM Employee;

-- 7. Aggregate functions
SELECT
    COUNT(*) AS total_employees,
    AVG(salary) AS average_salary,
    MAX(salary) AS highest_salary,
    MIN(salary) AS lowest_salary,
    SUM(salary) AS total_salary
FROM Employee;

-- 8. GROUP BY: employee count by department ID
SELECT dept_id, COUNT(*) AS employee_count
FROM Employee
GROUP BY dept_id;

-- 9. GROUP BY: employee count by department name
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_name;

-- 10. CASE expression: categorize employees by salary
SELECT
    emp_name,
    salary,
    CASE
        WHEN salary >= 90000 THEN 'High Salary'
        WHEN salary >= 70000 THEN 'Medium Salary'
        ELSE 'Low Salary'
    END AS salary_category
FROM Employee;

-- 11. ORDER BY: employees sorted by salary, highest first
SELECT emp_name, salary
FROM Employee
ORDER BY salary DESC;

-- 12. Join Employee, Department, and Project
SELECT
    e.emp_id,
    e.emp_name,
    d.dept_name,
    p.project_name,
    e.salary
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id
JOIN Project p ON e.project_id = p.project_id;

-- 13. Project-wise employee count
SELECT
    p.project_name,
    COUNT(e.emp_id) AS employee_count
FROM Project p
LEFT JOIN Employee e ON p.project_id = e.project_id
GROUP BY p.project_name
ORDER BY employee_count DESC;

-- 14. Department-wise total salary
SELECT
    d.dept_name,
    SUM(e.salary) AS total_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
ORDER BY total_salary DESC;

-- 15. GROUP BY, HAVING, and ORDER BY
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS highest_salary
FROM Department d
JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_name
HAVING AVG(e.salary) > 70000
ORDER BY average_salary DESC;
