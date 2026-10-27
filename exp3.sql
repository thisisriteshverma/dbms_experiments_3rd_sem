-- EXPERIMENT 3: Employee-Department-Project Schema
-- Name: Ritesh Verma | Class: AIML-4(B)
-- Roll No: 26LBCS8305
-- Database: MySQL

CREATE DATABASE IF NOT EXISTS company_db;
USE company_db;

-- 1. Create tables
CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

CREATE TABLE Project (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    salary DECIMAL(10,2),
    hire_date DATE,
    dept_id INT,
    project_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
);

-- 2. Insert 5 departments
INSERT INTO Department (dept_id, dept_name, location) VALUES
(1, 'IT', 'Delhi'),
(2, 'HR', 'Mumbai'),
(3, 'Finance', 'Bangalore'),
(4, 'Marketing', 'Pune'),
(5, 'Operations', 'Hyderabad');

-- 3. Insert 8 projects
INSERT INTO Project (project_id, project_name, budget, dept_id) VALUES
(101, 'E-Commerce Platform', 1500000, 1),
(102, 'AI Chatbot', 800000, 1),
(103, 'Employee Portal', 600000, 2),
(104, 'Financial Analytics', 1800000, 3),
(105, 'Digital Marketing', 1200000, 4),
(106, 'Supply Chain System', 1000000, 5),
(107, 'Cloud Migration', 2200000, 1),
(108, 'Customer Management', 1300000, 4);

-- 4. Insert 30 employees
INSERT INTO Employee (emp_id, emp_name, salary, hire_date, dept_id, project_id) VALUES
(1,  'Aarav Sharma', 75000, '2021-01-15', 1, 101),
(2,  'Priya Singh', 85000, '2020-08-28', 1, 102),
(3,  'Rahul Verma', 65000, '2022-06-10', 1, 107),
(4,  'Ananya Gupta', 95000, '2019-08-12', 1, 102),
(5,  'Rohan Mehta', 70000, '2021-11-05', 1, 101),
(6,  'Sneha Kapoor', 80000, '2020-09-18', 1, 107),
(7,  'Vikas Kumar', 55000, '2022-04-10', 2, 103),
(8,  'Neha Joshi', 60000, '2021-04-22', 2, 103),
(9,  'Karan Malhotra', 58000, '2022-07-15', 2, 103),
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
