-- EXPERIMENT 6: Stored Procedure, Salary Validation, and Audit Logging
-- Name: Ritesh Verma | Class: AIML-4(B) | Roll No: 26LBCS8305
-- MySQL
-- This script assumes company_db, Department, and Employee exist.
-- For the Employee columns, this experiment uses emp_id, emp_name, salary,
-- hire_date, dept_id, project_id, and manager_id if present.
USE company_db;

-- 1. Create an audit table for salary changes
CREATE TABLE IF NOT EXISTS SalaryAudit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(20) NOT NULL
);

-- 2. Salary validation trigger for new employees
DROP TRIGGER IF EXISTS validate_salary;

DELIMITER //
CREATE TRIGGER validate_salary
BEFORE INSERT ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary must be greater than 0';
    END IF;
END //
DELIMITER ;

-- 3. Salary validation trigger for salary updates
DROP TRIGGER IF EXISTS validate_salary_update;

DELIMITER //
CREATE TRIGGER validate_salary_update
BEFORE UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF NEW.salary IS NULL OR NEW.salary <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Salary must be greater than 0';
    END IF;
END //
DELIMITER ;

-- 4. Audit trigger: log salary changes
DROP TRIGGER IF EXISTS salary_audit_trigger;

DELIMITER //
CREATE TRIGGER salary_audit_trigger
AFTER UPDATE ON Employee
FOR EACH ROW
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO SalaryAudit (
            emp_id, old_salary, new_salary, action
        )
        VALUES (
            OLD.emp_id, OLD.salary, NEW.salary, 'SALARY UPDATE'
        );
    END IF;
END //
DELIMITER ;

-- 5. Stored procedure: transfer an employee to another department
DROP PROCEDURE IF EXISTS transfer_employee;

DELIMITER //
CREATE PROCEDURE transfer_employee(
    IN p_emp_id INT,
    IN p_new_dept_id INT
)
BEGIN
    DECLARE employee_count INT DEFAULT 0;
    DECLARE department_count INT DEFAULT 0;
    DECLARE current_dept_id INT DEFAULT NULL;

    -- On any SQL exception, roll back the transaction and return a message.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Transfer failed. Transaction rolled back.' AS message;
    END;

    START TRANSACTION;

    -- Validate employee
    SELECT COUNT(*) INTO employee_count
    FROM Employee
    WHERE emp_id = p_emp_id;

    IF employee_count = 0 THEN
