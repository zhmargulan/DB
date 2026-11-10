-- PART 1

CREATE TABLE employees (
                           emp_id    INT PRIMARY KEY,
                           emp_name  VARCHAR(50),
                           dept_id   INT,
                           salary    DECIMAL(10, 2)
);

CREATE TABLE departments (
                             dept_id   INT PRIMARY KEY,
                             dept_name VARCHAR(50),
                             location  VARCHAR(50)
);

CREATE TABLE projects (
                          project_id   INT PRIMARY KEY,
                          project_name VARCHAR(50),
                          dept_id      INT,
                          budget       DECIMAL(10, 2)
);

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
                                                              (1, 'John Smith',     101, 50000),
                                                              (2, 'Jane Doe',       102, 60000),
                                                              (3, 'Mike Johnson',   101, 55000),
                                                              (4, 'Sarah Williams', 103, 65000),
                                                              (5, 'Tom Brown',      NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
                                                           (101, 'IT',        'Building A'),
                                                           (102, 'HR',        'Building B'),
                                                           (103, 'Finance',   'Building C'),
                                                           (104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
                                                                     (1, 'Website Redesign',   101, 100000),
                                                                     (2, 'Employee Training',  102, 50000),
                                                                     (3, 'Budget Analysis',    103, 75000),
                                                                     (4, 'Cloud Migration',    101, 150000),
                                                                     (5, 'AI Research',        NULL, 200000);



-- PART 2
-- 2.1

CREATE OR REPLACE VIEW employs_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employs_details;
-- It returns only employees who have a non-null dept_id that matches a row in departments. The count 4.

-- 2.2

CREATE OR REPLACE VIEW dept_statistics AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS maximum_salary,
    MIN(e.salary) AS minimum_salary
FROM departments d
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

-- 2.3

CREATE OR REPLACE VIEW project_overview AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS team_size
FROM projects p
         JOIN departments d ON p.dept_id = d.dept_id
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

SELECT * FROM project_overview;

-- 2.4

CREATE OR REPLACE VIEW high_earners AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id WHERE e.salary > 55000;

SELECT * FROM high_earners;

-- You see only high-earning employees who are assigned to a matching department. High earners with dept_id IS NULL or
-- an invalid department are not shown because of the inner JOIN.



-- PART 3
-- 3.1

CREATE OR REPLACE VIEW employee_details AS
SELECT
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
        END as salary_grade
FROM employees e
         JOIN departments d ON e.dept_id = d.dept_id;

SELECT * FROM employee_details;

-- 3.2

ALTER VIEW high_earners RENAME TO top_performers;

SELECT * FROM top_performers;

-- 3.3

CREATE OR REPLACE VIEW temp_view AS
SELECT * FROM employees WHERE salary < 50000;

DROP VIEW temp_view;



-- PART 4
-- 4.1

CREATE OR REPLACE VIEW employee_salaries AS
SELECT
    emp_id, emp_name, dept_id, salary
FROM employees;

-- 4.2

UPDATE employee_salaries SET salary = 52000 WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith'

-- 4.3

    INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees;
-- It should succeed if emp_id = 6 does not already exist and dept_id = 102 exists in departments. If a foreign-key or
-- primary-key constraint fails, fix the referenced value or ID first.

-- 4.4

CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
    WITH LOCAL CHECK OPTION;

-- This should fail
INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);
-- ОШИБКА: новая строка нарушает ограничение-проверку для представления "it_employees"
-- Detail: Ошибочная строка содержит (7, Bob Wilson, 103, 60000.00).



-- PART 5
-- 5.1

CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id,
    d.dept_name,
    COALESCE(emp.total_employees, 0) AS total_employees,
    COALESCE(emp.total_salaries, 0) AS total_salaries,
    COALESCE(pr.total_projects, 0) AS total_projects,
    COALESCE(pr.total_project_budget, 0) AS total_budget
FROM departments d
         LEFT JOIN (
    SELECT dept_id, COUNT(*) AS total_employees, SUM(salary) AS total_salaries
    FROM employees
    GROUP BY dept_id
) emp ON d.dept_id = emp.dept_id
         LEFT JOIN (
    SELECT dept_id, COUNT(*) AS total_projects, SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
) pr ON d.dept_id = pr.dept_id
    WITH DATA;

SELECT * FROM dept_summary_mv
ORDER BY total_employees DESC;

-- 5.2

INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000 );

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- Before refresh, the materialized view still shows the old cached data. After REFRESH MATERIALIZED VIEW, it shows
-- the new employee count and total salaries. Regular views update automatically; materialized views do not.

-- 5.3

CREATE UNIQUE INDEX dept_summary_mv_dept_id_idx ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

-- REFRESH MATERIALIZED VIEW CONCURRENTLY allows other sessions to continue reading the materialized view while it is
-- being refreshed. A normal refresh locks the view and blocks reads. It requires a unique index.

-- 5.4

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS eployee_count
FROM projects p
         JOIN departments d ON p.dept_id = d.dept_id
         LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
    WITH NO DATA;

SELECT * FROM project_stats_mv;

--  ОШИБКА: материализованное представление "project_stats_mv" не было наполнено
--  Hint: Примените команду REFRESH MATERIALIZED VIEW.

REFRESH MATERIALIZED VIEW project_stats_mv;
SELECT * FROM project_stats_mv;



-- PART 6
-- 6.1

CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer NOLOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

-- 6.2

CREATE ROLE db_creator CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user SUPERUSER LOGIN PASSWORD 'admin999';

-- 6.3

GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- 6.4

CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE ROLE hr_user1 PASSWORD 'hr001';
CREATE ROLE hr_user2 PASSWORD 'hr002';
CREATE ROLE finance_user1 PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- 6.5

REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- 6.6

ALTER ROLE analyst LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;



-- PART 7
-- 7.1

CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- 7.2

CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

-- 7.3
CREATE ROLE temp_owner LOGIN;

CREATE TABLE temp_table (id INT);

ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- If you also want to remove temp_table after reassignment:
-- DROP TABLE temp_table;

-- 7.4
CREATE OR REPLACE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;



-- PART 8
-- 8.1

CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,
    COALESCE(emp.employee_count, 0) AS employee_count,
    ROUND(COALESCE(emp.avg_salary, 0), 2) AS average_salary,
    COALESCE(pr.project_count, 0) AS active_projects,
    COALESCE(pr.total_project_budget, 0) AS total_project_budget,
    ROUND(
            CASE
                WHEN COALESCE(emp.employee_count, 0) = 0 THEN 0
                ELSE COALESCE(pr.total_project_budget, 0)::numeric / emp.employee_count
        END,
            2
    ) AS budget_per_employee
FROM departments d
         LEFT JOIN (
    SELECT dept_id, COUNT(*) AS employee_count, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
) emp ON d.dept_id = emp.dept_id
         LEFT JOIN (
    SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
) pr ON d.dept_id = pr.dept_id;

SELECT * FROM dept_dashboard;

-- 8.2
ALTER TABLE projects
    ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
        END AS approval_status
FROM projects p
         JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;

-- 8.3
-- Level 1
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

-- Level 2
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Users
CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;