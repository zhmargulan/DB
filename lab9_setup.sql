-- ============================================================
-- Lab 9: Stored Procedures and User-Defined Functions
-- Single SQL file: setup, functions, tests, answers
-- ============================================================

-- ============================================================
-- Part 1: Database Setup
-- ============================================================
DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

CREATE TABLE stations (
                          station_id   INT PRIMARY KEY,
                          station_name VARCHAR(50) NOT NULL,
                          city         VARCHAR(40) NOT NULL,
                          capacity     INT NOT NULL
);

CREATE TABLE bikes (
                       bike_id    INT PRIMARY KEY,
                       model      VARCHAR(50) NOT NULL,
                       station_id INT REFERENCES stations(station_id),
                       daily_rate NUMERIC(8,2) NOT NULL
);

CREATE TABLE members (
                         member_id INT PRIMARY KEY,
                         full_name VARCHAR(60) NOT NULL,
                         city      VARCHAR(40) NOT NULL,
                         joined_on DATE NOT NULL
);

CREATE TABLE rentals (
                         rental_id  INT PRIMARY KEY,
                         member_id  INT REFERENCES members(member_id),
                         bike_id    INT REFERENCES bikes(bike_id),
                         start_date DATE NOT NULL,
                         end_date   DATE,
                         fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
                         (10, 'Central Park', 'Almaty',   4),
                         (20, 'Riverside',    'Almaty',   3),
                         (30, 'Expo Gate',    'Astana',   5),
                         (40, 'Old Town',     'Shymkent', 2),
                         (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
                      (101, 'City Cruiser', 10,  4.50),
                      (102, 'City Cruiser', 10,  4.50),
                      (103, 'Mountain X',   20,  7.00),
                      (104, 'Mountain X',   30,  7.00),
                      (105, 'Road Sprint',  30,  9.25),
                      (106, 'Folding Mini', 40,  3.75),
                      (107, 'Cargo Hauler', 20, 12.00),
                      (108, 'Road Sprint',  10,  9.25);

INSERT INTO members VALUES
                        (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
                        (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
                        (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
                        (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
                        (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
                        (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
                        ( 1, 1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
                        ( 2, 1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
                        ( 3, 1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
                        ( 4, 1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
                        ( 5, 2, 101, DATE '2024-05-01', DATE '2024-05-02',  4.50),
                        ( 6, 2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
                        ( 7, 2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
                        ( 8, 3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
                        ( 9, 3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
                        (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10',  7.00),
                        (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
                        (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
                        (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
                        (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
                        (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
                        (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20',  7.50),
                        (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
                        (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
                        (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
                        (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
                        (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
                        (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes)    AS bikes,
       (SELECT COUNT(*) FROM members)  AS members,
       (SELECT COUNT(*) FROM rentals)  AS rentals;


-- Part 2


-- Exercise 2.1
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT)
RETURNS INT AS $$
DECLARE
v_days INT;
BEGIN
SELECT end_date - start_date
INTO v_days
FROM rentals
WHERE rental_id = p_rental_id;
RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);
SELECT rental_days(11);
-- Q: rental 19 returns NULL because end_date IS NULL.
-- Q: rental 999 returns NULL because no row exists.
-- Q: the NULLs have different causes: NULL arithmetic vs no row found.

-- Exercise 2.2
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT)
RETURNS INT AS $$
DECLARE
v_count INT;
BEGIN
SELECT COUNT(*)
INTO v_count
FROM rentals
WHERE member_id = p_member_id;
RETURN v_count;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);
SELECT member_rental_count(5);
SELECT member_rental_count(6);
-- Q: COUNT(*) returns 0, not NULL, because an aggregate over an empty
-- row set still returns one row containing 0.

-- Exercise 2.3
CREATE OR REPLACE FUNCTION station_city(p_station_id INT)
RETURNS VARCHAR AS $$
DECLARE
v_city VARCHAR;
BEGIN
SELECT city
INTO v_city
FROM stations
WHERE station_id = p_station_id;
RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

-- Exercise 2.4
SELECT rental_id,
       member_id,
       rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC, rental_id;


-- Part 3


-- Exercise 3.1
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
RETURN ROUND(p_fee * (1 - p_percent / 100.0), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

-- Exercise 3.2
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE
) AS $$
BEGIN
SELECT COUNT(*)::INT,
    COALESCE(SUM(fee), 0)::NUMERIC,
    MAX(start_date)
INTO rental_cnt, total_fee, last_start
FROM rentals
WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);
-- Q: SELECT member_stats(3) returns one composite/record value.
-- Q: SELECT * FROM member_stats(3) returns three separate columns.
-- Q: Use SELECT * FROM member_stats(...) or LATERAL inside a larger query,
-- because separate columns are easier to use.
-- Q: Member 6 returns rental_cnt = 0, total_fee = 0.00, last_start = NULL.

-- Exercise 3.3
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC)
AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(13.50);
-- Q: It produces a value because an INOUT parameter is automatically
-- returned as the function result; no RETURNS clause or RETURN is needed.

-- Exercise 3.4
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC
) AS $$
BEGIN
SELECT COALESCE(SUM(p_fees[i]), 0),
       COALESCE(ROUND(AVG(p_fees[i]), 2), 0),
       MAX(p_fees[i])
INTO total, average, largest
FROM generate_subscripts(p_fees, 1) AS g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
SELECT * FROM fee_summary();
-- Q: fee_summary() with no arguments returns 0, 0, NULL with this code.
-- Q: A VARIADIC parameter must be last because PostgreSQL must know where
-- the variable-length argument list ends.

-- Exercise 3.5
-- (a) IN: the id is only read.
-- (b) INOUT: the caller passes a balance in and expects it back updated.
-- (c) VARIADIC: an unknown number of values of the same type.
-- (d) OUT: several values returned from one function call.


-- Part 4


-- Exercise 4.1
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT)
RETURNS NUMERIC AS $$
DECLARE
v_total NUMERIC;
BEGIN
SELECT COALESCE(SUM(fee), 0)
INTO v_total
FROM rentals
WHERE member_id = p_member_id;
RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1);
SELECT total_fees(6);

-- Exercise 4.2
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
v_total NUMERIC;
BEGIN
SELECT COALESCE(SUM(fee), 0)
INTO v_total
FROM rentals
WHERE member_id = p_member_id
  AND start_date >= p_from_date;
RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

-- Exercise 4.3
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01'
)
RETURNS NUMERIC AS $$
DECLARE
v_total NUMERIC;
BEGIN
SELECT COALESCE(SUM(fee), 0)
INTO v_total
FROM rentals
WHERE member_id = p_member_id
  AND start_date >= p_from_date;
RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- SELECT total_fees(1);
-- ERROR:  function total_fees(integer) is not unique
-- LINE 1: SELECT total_fees(1);
--                ^
-- HINT:  Could not choose a best candidate function. You might need to add explicit type casts.
-- Q: PostgreSQL cannot choose between total_fees(INT) and
-- total_fees(INT, DATE DEFAULT ...), because both accept one integer argument.

-- Exercise 4.4
DROP FUNCTION total_fees(INTEGER);

SELECT total_fees(1);
-- Q: The two-argument version with the default date answers the call.
-- Q: It returns 50.00.
-- Q: Dropping the other version would return 98.50, so the answer would differ.

-- Exercise 4.5
CREATE OR REPLACE FUNCTION total_fees(p_full_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
v_total NUMERIC;
BEGIN
SELECT COALESCE(SUM(r.fee), 0)
INTO v_total
FROM members m
         LEFT JOIN rentals r ON r.member_id = m.member_id
WHERE m.full_name = p_full_name;
RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);
-- Q: Adding this version does not reintroduce ambiguity because the calls
-- have different argument types.
-- Q: total_fees('Aisha Nurlanova') reaches the VARCHAR version and sums all
-- fees for Aisha: 98.50.
-- Q: total_fees(1) reaches the INT + DEFAULT DATE version and sums only
-- rentals from 2025-01-01 onwards: 50.00.


-- Part 5

-- Exercise 5.1
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE (
    found_id INT,
    found_model VARCHAR,
    found_rate NUMERIC
) AS $$
BEGIN
RETURN QUERY
SELECT b.bike_id, b.model, b.daily_rate
FROM bikes b
WHERE b.model ILIKE p_pattern
ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
-- SELECT find_bikes('%road%');
-- Q: Without FROM, the result is one composite/record column per row.
-- Q: With FROM, the function is expanded into separate columns.

-- Exercise 5.2
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE (
    rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    days INT,
    fee NUMERIC
) AS $$
BEGIN
RETURN QUERY
SELECT r.rental_id,
       b.model,
       s.station_name,
       (r.end_date - r.start_date)::INT,
    r.fee
FROM rentals r
         JOIN bikes b ON b.bike_id = r.bike_id
         JOIN stations s ON s.station_id = b.station_id
WHERE r.member_id = p_member_id
ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- Exercise 5.3
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
RETURN QUERY
SELECT bike_id, model
FROM bikes
WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

-- SELECT * FROM bike_list(10);
-- ERROR:  column reference "bike_id" is ambiguous
-- LINE 1: SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
--                ^
-- DETAIL:  It could refer to either a PL/pgSQL variable or a table column.
-- QUERY:  SELECT bike_id, model FROM bikes WHERE station_id = p_station_id
-- CONTEXT:  PL/pgSQL function bike_list(integer) line 3 at RETURN QUERY
-- Q: CREATE succeeds because PL/pgSQL does not fully resolve the query
-- until the function is called. The error appears at call time.

DROP FUNCTION bike_list(INT);

CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
RETURN QUERY
SELECT b.bike_id, b.model
FROM bikes b
WHERE b.station_id = p_station_id
ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

DROP FUNCTION bike_list(INT);

CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE (bike_id INT, model VARCHAR) AS $$
BEGIN
RETURN QUERY
SELECT b.bike_id, b.model
FROM bikes b
WHERE b.station_id = p_station_id
ORDER BY b.bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);
-- Fix 1: rename output columns.
-- Fix 2: keep names and qualify table columns with an alias.

-- Exercise 5.4
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
RETURN QUERY
SELECT s.station_name,
       COUNT(*),
       s.capacity - COUNT(*)
FROM stations s
         LEFT JOIN bikes b ON b.station_id = s.station_id
WHERE s.city = p_city
GROUP BY s.station_id, s.station_name, s.capacity
ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

-- SELECT * FROM station_board('Almaty');
-- ERROR:  structure of query does not match function result type
-- DETAIL:  Returned type bigint does not match expected type integer in column 2.
-- CONTEXT:  PL/pgSQL function station_board(character varying) line 3 at RETURN QUERY

CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE (s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
RETURN QUERY
SELECT s.station_name,
       COUNT(b.bike_id)::INT,
    (s.capacity - COUNT(b.bike_id))::INT
FROM stations s
         LEFT JOIN bikes b ON b.station_id = s.station_id
WHERE s.city = p_city
GROUP BY s.station_id, s.station_name, s.capacity
ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');
SELECT * FROM station_board('Astana');
-- Q: COUNT(*) returns BIGINT, so it must be cast to INT for the declared
-- output column.


-- Part 6


-- Exercise 6.1
DO $$
<<rental_report>>
DECLARE
total_rentals INTEGER := 0;
BEGIN
SELECT COUNT(*) INTO total_rentals FROM rentals;
RAISE NOTICE 'The rentals table holds % rows', total_rentals;
END rental_report $$;
-- Q: If the label after END does not match the top label, PostgreSQL raises
-- a block-label mismatch error.

-- Exercise 6.2
DO $$
<<rental_report>>
DECLARE
fee_total NUMERIC := 0;
BEGIN
SELECT COALESCE(SUM(fee), 0) INTO fee_total FROM rentals;
RAISE NOTICE 'outer before subblock: %', fee_total;

    DECLARE
fee_total NUMERIC := 0;
BEGIN
SELECT COALESCE(SUM(fee), 0)
INTO fee_total
FROM rentals
WHERE start_date >= DATE '2025-01-01';

RAISE NOTICE 'subblock value: %', fee_total;
        RAISE NOTICE 'outer via label: %', rental_report.fee_total;
END;

    RAISE NOTICE 'outer after subblock: %', fee_total;
END rental_report $$;
-- Q: The four numbers are 621.50, 369.00, 621.50, 621.50.
-- Q: The assignment inside the subblock did not change the outer variable.
-- Q: A declaration is local to its block; the inner variable shadows the outer.

-- Exercise 6.3
-- DO $$
-- <<outer_block>>
-- DECLARE
--     outer_var INT := 1;
-- BEGIN
--     DECLARE
--         inner_var INT := 2;
--     BEGIN
--         RAISE NOTICE 'inner_var = %', inner_var;
--     END;
--
--     DECLARE
--     BEGIN
--         RAISE NOTICE 'inner_var = %', inner_var;
--     END;
-- END outer_block $$;
-- ERROR:  column "inner_var" does not exist

DO $$
<<outer_block>>
DECLARE
outer_var INT := 1;
    inner_var INT := 2;
BEGIN
    DECLARE
BEGIN
        RAISE NOTICE 'first subblock sees inner_var = %', inner_var;
END;

    DECLARE
BEGIN
        RAISE NOTICE 'second subblock sees inner_var = %', inner_var;
END;
END outer_block $$;

-- Exercise 6.4
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC
) AS $$
BEGIN
SELECT COALESCE(SUM(fee) FILTER (WHERE start_date < p_from_date), 0),
       COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
INTO before_total, after_total
FROM rentals;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_split(DATE '2025-01-01');


-- Part 7


-- Exercise 7.1
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC
) AS $$
DECLARE
v_capacity INT;
BEGIN
SELECT COUNT(*)::INT
INTO bikes_parked
FROM bikes
WHERE station_id = p_station_id;

SELECT capacity
INTO v_capacity
FROM stations
WHERE station_id = p_station_id;

IF v_capacity IS NULL OR v_capacity = 0 THEN
        capacity_pct := NULL;
ELSE
        capacity_pct := ROUND(100.0 * bikes_parked / v_capacity, 1);
END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s,
     LATERAL station_load(s.station_id) l
ORDER BY s.station_id;
-- Q: Station 50 has capacity 0, so capacity_pct is returned as NULL.
-- The percentage is undefined; NULL avoids division by zero.

-- Exercise 7.2
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE (
    member_name VARCHAR,
    rental_count INT,
    total_spent NUMERIC
) AS $$
BEGIN
RETURN QUERY
SELECT m.full_name,
       COUNT(r.rental_id)::INT,
    COALESCE(SUM(r.fee), 0)::NUMERIC
FROM members m
         LEFT JOIN rentals r ON r.member_id = m.member_id
GROUP BY m.member_id, m.full_name
ORDER BY COALESCE(SUM(r.fee), 0) DESC, m.full_name
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);
-- Q: Aisha Nurlanova has more rentals than Daniyar Serik but is ranked lower.
-- This is not a bug: ranking is by total amount spent, not by rental count.

-- Exercise 7.3
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE (
    member_name VARCHAR,
    bike_model VARCHAR,
    days INT,
    amount_owed NUMERIC,
    status TEXT
) AS $$
BEGIN
RETURN QUERY
SELECT m.full_name,
       b.model,
       CASE
           WHEN r.end_date IS NULL THEN CURRENT_DATE - r.start_date
           ELSE r.end_date - r.start_date
           END,
       ROUND(
               (CASE
                    WHEN r.end_date IS NULL THEN CURRENT_DATE - r.start_date
                    ELSE r.end_date - r.start_date
                   END) * b.daily_rate,
               2
       ),
       CASE
           WHEN r.end_date IS NULL THEN 'OPEN'
           ELSE 'CLOSED'
           END
FROM rentals r
         JOIN members m ON m.member_id = r.member_id
         JOIN bikes b ON b.bike_id = r.bike_id
WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
-- Q: For rental 11 the calculated amount is 8 * 9.25 = 74.00, which equals
-- the stored fee.
-- Q: For rental 19 the amount changes every day because end_date is NULL and
-- the function uses CURRENT_DATE.
-- Q: A function that depends on CURRENT_DATE cannot be IMMUTABLE.

-- Exercise 7.4
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE (
    member_count INT,
    rental_count INT,
    total_revenue NUMERIC
) AS $$
BEGIN
RETURN QUERY
SELECT COUNT(DISTINCT m.member_id)::INT,
    COUNT(r.rental_id)::INT,
    COALESCE(SUM(r.fee), 0)::NUMERIC
FROM members m
         LEFT JOIN rentals r ON r.member_id = m.member_id
WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE (
    member_count INT,
    rental_count INT,
    total_revenue NUMERIC
) AS $$
BEGIN
RETURN QUERY
SELECT COUNT(DISTINCT m.member_id)::INT,
    COUNT(r.rental_id)::INT,
    COALESCE(SUM(r.fee), 0)::NUMERIC
FROM members m
         LEFT JOIN rentals r
                   ON r.member_id = m.member_id
                       AND r.start_date >= p_from_date
WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
-- Q: The date condition belongs in the ON clause if members with no
-- qualifying rentals must still be counted.
-- Q: With the date in ON, Almaty member count is 3.
-- Q: With the date in WHERE, Almaty member count becomes 2, because Elena
-- Petrova has no rentals and is filtered out.


-- Lab Questions

-- 1. The name is only the identifier. The signature is the name plus the
-- input argument types. PostgreSQL needs the signature to drop a specific
-- overloaded function.
-- 2. Dollar quoting $$ avoids escaping single quotes inside the body. It is
-- useful when the body contains many string literals.
-- 3. Use several OUT parameters for one row of several scalar values. Use
-- RETURNS TABLE when the function naturally returns a set of rows.
-- 4. A VARIADIC parameter must be last so PostgreSQL can collect all
-- remaining arguments into the array unambiguously.
-- 5. RETURN returns one value from a scalar function. RETURN QUERY appends
-- the rows of a SELECT to a set-returning function.
-- 6. A DEFAULT parameter can make an old one-argument call match both the
-- old one-argument function and the new two-argument function with a default.
-- Avoid overlapping signatures, drop the old version, or require casts.
-- 7. A subblock variable is destroyed when the subblock ends. Read a
-- shadowed outer variable by qualifying it with the outer block label.
-- 8. Advantage: one central definition and EXECUTE without direct table
-- access. Disadvantage: database-specific code, harder to version/test, and
-- CPU work moves to the database server.
-- 9. A trusted language such as PL/pgSQL cannot access the file system or
-- network and may be used by ordinary users. An untrusted language such as
-- PL/Python or C can access external resources, so only a superuser may
-- create functions in it.
-- 10. CREATE OR REPLACE with changed argument types creates a new overloaded
-- function instead of replacing the old one. The old function remains and
-- can cause ambiguity. You must explicitly drop the old signature.