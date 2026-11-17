-- PART 1

DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP VIEW  IF EXISTS index_documentation;

CREATE TABLE departments (
                             dept_id INT PRIMARY KEY,
                             dept_name VARCHAR(50),
                             location VARCHAR(50)
);

CREATE TABLE employees (
                           emp_id INT PRIMARY KEY,
                           emp_name VARCHAR(100),
                           dept_id INT,
                           salary DECIMAL(10,2),
                           FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
                          proj_id INT PRIMARY KEY,
                          proj_name VARCHAR(100),
                          budget DECIMAL(12,2),
                          dept_id INT,
                          FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
                            (101, 'IT', 'Building A'),
                            (102, 'HR', 'Building B'),
                            (103, 'Operations', 'Building C');

INSERT INTO employees VALUES
                          (1, 'John Smith', 101, 50000),
                          (2, 'Jane Doe', 101, 55000),
                          (3, 'Mike Johnson', 102, 48000),
                          (4, 'Sarah Williams', 102, 52000),
                          (5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
                         (201, 'Website Redesign', 75000, 101),
                         (202, 'Database Migration', 120000, 101),
                         (203, 'HR System Upgrade', 50000, 102);

-- PART 2
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT '--- 2.1: indexes on employees ---' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';

CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT '--- 2.2: test FK index ---' AS info;
EXPLAIN SELECT * FROM employees WHERE dept_id = 101;
SELECT * FROM employees WHERE dept_id = 101;

SELECT '--- 2.3: all indexes in public schema ---' AS info;
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- PART 3

CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT '--- 3.1: test multicolumn index ---' AS info;
EXPLAIN SELECT emp_name, salary FROM employees
        WHERE dept_id = 101 AND salary > 52000;

CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT '--- 3.2: reversed column order ---' AS info;
EXPLAIN SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
EXPLAIN SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

-- PART 4

ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com'     WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com'       WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com'   WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com'      WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

SELECT '--- 4.1: test unique constraint (expected failure) ---' AS info;
DO $$
BEGIN
INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
RAISE NOTICE 'Insert succeeded (UNEXPECTED!)';
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'Expected error: duplicate key on email (unique_violation)';
END $$;

ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT '--- 4.2: auto-created phone index ---' AS info;
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- PART 5

CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT '--- 5.1: DESC index for ORDER BY ---' AS info;
EXPLAIN SELECT emp_name, salary FROM employees ORDER BY salary DESC;

CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT '--- 5.2: NULLS FIRST index ---' AS info;
EXPLAIN SELECT proj_name, budget FROM projects ORDER BY budget NULLS FIRST;

-- PART 6

CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT '--- 6.1: LOWER() expression index ---' AS info;
EXPLAIN SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2001-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2030-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2048-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT '--- 6.2: EXTRACT(YEAR) index ---' AS info;
EXPLAIN SELECT emp_name, hire_date FROM employees
        WHERE EXTRACT(YEAR FROM hire_date) = 2020;

-- PART 7

ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT '--- 7.1: after rename ---' AS info;
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

DROP INDEX emp_salary_dept_idx;

SELECT '--- 7.2: after drop ---' AS info;
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

REINDEX INDEX employees_salary_index;

-- PART 8

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

SELECT '--- 8.1: JOIN + WHERE + ORDER BY plan ---' AS info;
EXPLAIN SELECT e.emp_name, e.salary, d.dept_name
        FROM employees e
                 JOIN departments d ON e.dept_id = d.dept_id
        WHERE e.salary > 50000
        ORDER BY e.salary DESC;

CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;

SELECT '--- 8.2: partial index plan ---' AS info;
EXPLAIN SELECT proj_name, budget FROM projects WHERE budget > 80000;

SELECT '--- 8.3: EXPLAIN salary filter ---' AS info;
EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- PART 9

CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT '--- 9.1: HASH index on dept_name ---' AS info;
EXPLAIN SELECT * FROM departments WHERE dept_name = 'IT';

CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx  ON projects USING HASH (proj_name);

SELECT '--- 9.2a: equality (both usable) ---' AS info;
EXPLAIN SELECT * FROM projects WHERE proj_name = 'Website Redesign';

SELECT '--- 9.2b: range (only B-tree works) ---' AS info;
EXPLAIN SELECT * FROM projects WHERE proj_name > 'Database';

-- PART 10

SELECT '--- 10.1: all indexes + sizes ---' AS info;
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

DROP INDEX IF EXISTS proj_name_hash_idx;

CREATE OR REPLACE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';

SELECT '--- 10.3: index documentation view ---' AS info;
SELECT * FROM index_documentation;

-- DONE
SELECT '=== ALL LAB 8 STEPS COMPLETED ===' AS info;