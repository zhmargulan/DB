--Part A

CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50)  NOT NULL,
    last_name  VARCHAR(50)  NOT NULL,
    department VARCHAR(50),
    salary     INTEGER      DEFAULT 30000,
    hire_date  DATE,
    status     VARCHAR(20)  DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50) NOT NULL,
    budget     INTEGER,
    manager_id INTEGER

);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

--Part B

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Aidar', 'Nurlan', 'IT'),
       (2, 'Madina', 'Sarsen', 'Sales');

SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Dana', 'Omar', 'IT', DEFAULT, DEFAULT);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT',    150000, 1),
       ('Sales',  90000, 2),
       ('HR',     60000, NULL);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Timur', 'Bek', 'IT', 50000 * 1.1, CURRENT_DATE);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Aliya',  'Kaim',   'Sales', 45000, '2018-03-15', 'Active'),
       ('Berik',  'Saken',  'Sales', 70000, '2019-07-01', 'Active'),
       ('Camila', 'Ruiz',   'IT',    90000, '2017-05-20', 'Active'),
       ('Daniyar','Ali',    'HR',    38000, '2023-06-10', 'Terminated'),
       ('Elena',  'Petrov', NULL,    35000, '2023-09-01', 'Active'),
       ('Farid',  'Khan',   'HR',    52000, '2021-02-11', 'Inactive');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Website Redesign', 1, '2022-01-01', '2022-12-31', 40000),
       ('CRM Rollout',      2, '2023-03-01', '2024-03-01', 80000),
       ('Hiring Drive',     3, '2022-05-01', '2022-11-30', 20000);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

--Part C

UPDATE employees
SET salary = ROUND(salary * 1.10);

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000              THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
    END;

SELECT emp_id, first_name, salary, department FROM employees ORDER BY emp_id;
ROLLBACK;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (SELECT ROUND(AVG(e.salary) * 1.20)
    FROM employees e
    WHERE e.department = d.dept_name)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

UPDATE employees
SET salary = ROUND(salary * 1.15),
    status = 'Promoted'
WHERE department = 'Sales';

--Part D

DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

DELETE FROM departments
WHERE dept_id::TEXT NOT IN (SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--Part E

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Gulnara', 'Temir', NULL, NULL, '2024-01-15');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

--Part F

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Hana', 'Lee', 'IT', 60000, '2022-04-04')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary AS old_salary
      FROM employees
      WHERE department = 'IT') AS old
WHERE e.emp_id = old.emp_id
RETURNING e.emp_id, old.old_salary, e.salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--Part G

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Hana', 'Lee', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
    FROM employees
    WHERE first_name = 'Hana'
    AND last_name  = 'Lee');

UPDATE employees e
SET salary = ROUND(e.salary * CASE
    WHEN (SELECT d.budget FROM departments d
    WHERE d.dept_name = e.department) > 100000 THEN 1.10 ELSE 1.05
    END)
WHERE e.salary IS NOT NULL;

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Bulk1', 'Test', 'IT',    50000, '2024-02-01', 'Active'),
       ('Bulk2', 'Test', 'IT',    51000, '2024-02-01', 'Active'),
       ('Bulk3', 'Test', 'IT',    52000, '2024-02-01', 'Active'),
       ('Bulk4', 'Test', 'IT',    53000, '2024-02-01', 'Active'),
       ('Bulk5', 'Test', 'Sales', 54000, '2024-02-01', 'Inactive');

UPDATE employees
SET salary = ROUND(salary * 1.10)
WHERE last_name = 'Test'
  AND first_name LIKE 'Bulk%';

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Extra1', 'IT', 'IT', 60000, '2024-03-01'),
       ('Extra2', 'IT', 'IT', 61000, '2024-03-01');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Cloud Migration', 1, '2024-01-01', '2024-12-31', 75000);

UPDATE projects p
SET end_date = end_date + 30
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
        JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3;

SELECT * FROM projects  ORDER BY project_id;
SELECT * FROM employees ORDER BY emp_id;