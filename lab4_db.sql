-- Создание таблиц
CREATE TABLE employees (
                           employee_id SERIAL PRIMARY KEY,
                           first_name VARCHAR(50),
                           last_name VARCHAR(50),
                           department VARCHAR(50),
                           salary NUMERIC(10,2),
                           hire_date DATE,
                           manager_id INTEGER,
                           email VARCHAR(100)
);
CREATE TABLE projects (
                          project_id SERIAL PRIMARY KEY,
                          project_name VARCHAR(100),
                          budget NUMERIC(12,2),
                          start_date DATE,
                          end_date DATE,
                          status VARCHAR(20)
);
CREATE TABLE assignments (
                             assignment_id SERIAL PRIMARY KEY,
                             employee_id INTEGER REFERENCES employees(employee_id),
                             project_id INTEGER REFERENCES projects(project_id),
                             hours_worked NUMERIC(5,1),
                             assignment_date DATE
);
-- Вставка тестовых данных
INSERT INTO employees (first_name, last_name, department,
                       salary, hire_date, manager_id, email) VALUES
                                                                 ('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
                                                                  'john.smith@company.com'),
                                                                 ('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
                                                                  'sarah.j@company.com'),
                                                                 ('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
                                                                  'mbrown@company.com'),
                                                                 ('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
                                                                  'emily.davis@company.com'),
                                                                 ('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
                                                                 ('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
                                                                  'lisa.a@company.com');
INSERT INTO projects (project_name, budget, start_date,
                      end_date, status) VALUES
                                            ('Website Redesign', 150000, '2024-01-01', '2024-06-30',
                                             'Active'),
                                            ('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
                                             'Active'),
                                            ('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
                                             'Completed'),
                                            ('Database Migration', 120000, '2024-01-10', NULL, 'Active');
INSERT INTO assignments (employee_id, project_id,
                         hours_worked, assignment_date) VALUES
                                                            (1, 1, 120.5, '2024-01-15'),
                                                            (2, 1, 95.0, '2024-01-20'),
                                                            (1, 4, 80.0, '2024-02-01'),
                                                            (3, 3, 60.0, '2024-03-05'),
                                                            (5, 2, 110.0, '2024-02-20'),
                                                            (6, 3, 75.5, '2024-03-10');



-- TASK 1

SELECT first_name || ' ' || last_name as full_name,department,salary FROM employees;

SELECT DISTINCT department FROM employees;

SELECT project_name, budget, CASE WHEN budget  > 150000 THEN 'Large'
                                  WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium' ELSE 'Small'
    END AS budget_category FROM projects;

SELECT first_name || ' ' || last_name as full_name, COALESCE(email, 'No email provided') as email FROM employees;

-- TASK 2

SELECT * FROM employees WHERE hire_date > '2020-01-01';

SELECT * FROM employees WHERE salary BETWEEN 60000 AND 70000;

SELECT * FROM employees WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

SELECT * FROM employees WHERE manager_id IS NOT NULL AND department = 'IT';

-- TASK 3

SELECT UPPER(first_name || ' ' || last_name) AS Name, LENGTH(last_name) AS last_name_length,
       SUBSTRING(email FROM 1 FOR 3) AS email_prefix FROM employees;

SELECT first_name || ' ' || last_name AS full_name, salary * 12 AS annual_salary,
       ROUND((salary * 12) / 12, 2) AS month_salary, salary * 0.1 AS
                                         ten_percent_salary FROM employees;

SELECT format('Project: %s - Budget: %s - Status: %s', project_name, budget, status) AS project_info FROM projects;

SELECT first_name || ' ' || last_name AS full_name, hire_date AS hire_date,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))
                                      AS years_with_company FROM employees;


-- TASK 4

SELECT department AS department, AVG(salary) AS avarage_salary FROM employees GROUP BY department;

SELECT p.project_name AS project_name, SUM(a.hours_worked) AS total_hours FROM projects p
                                                                                   JOIN assignments a ON p.project_id = a.project_id GROUP BY p.project_name;

SELECT department, COUNT(*) AS employee_count FROM employees GROUP BY department HAVING COUNT(*) > 1;

SELECT MIN(salary) AS minimum_salary, MAX(salary) AS maximum_salary, SUM(salary) AS total_salaries FROM employees;


-- TASK 5

SELECT employee_id, first_name || ' ' || last_name AS full_name, salary FROM employees WHERE salary > 65000
UNION
SELECT employee_id, first_name || ' ' || last_name AS full_name,
       salary FROM employees WHERE hire_date > '2020-01-01';

SELECT employee_id, first_name || ' ' || last_name AS full_name, salary FROM employees WHERE department = 'IT'
INTERSECT
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary FROM employees
WHERE salary > 65000;

SELECT employee_id, first_name || ' ' || last_name AS full_name FROM employees
EXCEPT
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS full_name FROM employees e
                                                                               JOIN assignments a ON e.employee_id = a.employee_id;


-- TASK 6

SELECT * FROM employees e WHERE EXISTS(
    SELECT 1 FROM assignments a WHERE a.employee_id = e.employee_id
);

SELECT * FROM employees WHERE employee_id IN (
    SELECT a.employee_id
    FROM assignments a
             JOIN projects p ON a.project_id = p.project_id
    WHERE p.status = 'Active'
);

SELECT * FROM employees WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);

-- TASK 7

SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    e.department,
    AVG(a.hours_worked) AS avg_hours,
    e.salary
FROM employees e
         LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY e.department, e.salary DESC;

SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS employees_assigned
FROM projects p
         JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_name
HAVING SUM(a.hours_worked) > 150;

SELECT
    e.department,
    COUNT(*) AS total_employees,
    AVG(e.salary) AS avg_salary,
    GREATEST(MAX(e.salary), AVG(e.salary)) AS highest_salary,
    LEAST(MIN(e.salary), AVG(e.salary)) AS lowest_salary
FROM employees e
GROUP BY e.department;