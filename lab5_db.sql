-- PART 1: CHECK Constraints

-- Task 1.1: Basic CHECK Constraint
CREATE TABLE employees (
                           employee_id INTEGER,
                           first_name TEXT,
                           last_name TEXT,
                           age INTEGER CHECK (age BETWEEN 18 AND 65),
                           salary NUMERIC CHECK (salary > 0)
);

-- Task 1.2: Named CHECK Constraint
CREATE TABLE products_catalog (
                                  product_id INTEGER,
                                  product_name TEXT,
                                  regular_price NUMERIC,
                                  discount_price NUMERIC,
                                  CONSTRAINT valid_discount CHECK (
                                      regular_price > 0 AND
                                      discount_price > 0 AND
                                      discount_price < regular_price
                                      )
);

-- Task 1.3: Multiple Column CHECK
CREATE TABLE bookings (
                          booking_id INTEGER,
                          check_in_date DATE,
                          check_out_date DATE,
                          num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
                          CONSTRAINT valid_dates CHECK (check_out_date > check_in_date)
);

-- Task 1.4: Testing CHECK Constraints
-- 1. Valid Inserts
INSERT INTO employees VALUES (1, 'Alice', 'Smith', 30, 50000.00);
INSERT INTO employees VALUES (2, 'Bob', 'Johnson', 45, 75000.50);

INSERT INTO products_catalog VALUES (101, 'Laptop', 1000.00, 850.00);
INSERT INTO products_catalog VALUES (102, 'Mouse', 50.00, 39.99);

INSERT INTO bookings VALUES (1, '2026-06-01', '2026-06-07', 2);
INSERT INTO bookings VALUES (2, '2026-07-10', '2026-07-15', 4);

-- PART 2: NOT NULL Constraints

-- Task 2.1: NOT NULL Implementation
CREATE TABLE customers (
                           customer_id INTEGER NOT NULL,
                           email TEXT NOT NULL,
                           phone TEXT, -- can be NULL
                           registration_date DATE NOT NULL
);

-- Task 2.2: Combining Constraints
CREATE TABLE inventory (
                           item_id INTEGER NOT NULL,
                           item_name TEXT NOT NULL,
                           quantity INTEGER NOT NULL CHECK (quantity >= 0),
                           unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
                           last_updated TIMESTAMP NOT NULL
);

INSERT INTO customers VALUES (1, 'alice@example.com', '555-0100', '2026-01-15');
INSERT INTO customers VALUES (2, 'bob@example.com', NULL, '2026-02-20'); -- phone is nullable

INSERT INTO inventory VALUES (1, 'Desk Chair', 15, 120.50, CURRENT_TIMESTAMP);

INSERT INTO customers VALUES (3, 'charlie@example.com', NULL, '2026-03-05');

-- PART 3: UNIQUE Constraints

CREATE TABLE users (
                       user_id INTEGER,
                       username TEXT,
                       email TEXT,
                       created_at TIMESTAMP,
                       CONSTRAINT unique_username UNIQUE (username),
                       CONSTRAINT unique_email UNIQUE (email)
);

-- Task 3.2: Multi-Column UNIQUE
CREATE TABLE course_enrollments (
                                    enrollment_id INTEGER,
                                    student_id INTEGER,
                                    course_code TEXT,
                                    semester TEXT,
                                    CONSTRAINT unique_student_course UNIQUE (student_id, course_code, semester)
);

-- Task 3.3 Testing UNIQUE constraints
INSERT INTO users VALUES (1, 'johndoe', 'john@example.com', CURRENT_TIMESTAMP);
INSERT INTO users VALUES (2, 'janedoe', 'jane@example.com', CURRENT_TIMESTAMP);

INSERT INTO course_enrollments VALUES (1, 101, 'CS101', 'Fall2026');

-- PART 4: PRIMARY KEY Constraints

-- Task 4.1: Single Column Primary Key
CREATE TABLE departments (
                             dept_id INTEGER PRIMARY KEY,
                             dept_name TEXT NOT NULL,
                             location TEXT
);

INSERT INTO departments VALUES (10, 'Human Resources', 'Building A');
INSERT INTO departments VALUES (20, 'Engineering', 'Building B');
INSERT INTO departments VALUES (30, 'Sales', 'Building C');

-- Task 4.2: Composite Primary Key
CREATE TABLE student_courses (
                                 student_id INTEGER,
                                 course_id INTEGER,
                                 enrollment_date DATE,
                                 grade TEXT,
                                 PRIMARY KEY (student_id, course_id)
);

-- PART 5: FOREIGN KEY Constraints

CREATE TABLE employees_dept (
                                emp_id INTEGER PRIMARY KEY,
                                emp_name TEXT NOT NULL,
                                dept_id INTEGER REFERENCES departments(dept_id),
                                hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Mark Taylor', 10, '2025-01-10');
INSERT INTO employees_dept VALUES (2, 'Sarah Connor', 20, '2025-03-15');


-- Task 5.2: Multiple Foreign Keys (Library System Schema)
CREATE TABLE authors (

                        author_id INTEGER PRIMARY KEY,
                         author_name TEXT NOT NULL,
                         country TEXT
);

CREATE TABLE publishers (
                            publisher_id INTEGER PRIMARY KEY,
                            publisher_name TEXT NOT NULL,
                            city TEXT
);

CREATE TABLE books (
                       book_id INTEGER PRIMARY KEY,
                       title TEXT NOT NULL,
                       author_id INTEGER REFERENCES authors(author_id),
                       publisher_id INTEGER REFERENCES publishers(publisher_id),
                       publication_year INTEGER,
                       isbn TEXT UNIQUE
);

-- Sample Data Inserts
INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO authors VALUES (2, 'George Orwell', 'UK');

INSERT INTO publishers VALUES (1, 'Bloomsbury', 'London');
INSERT INTO publishers VALUES (2, 'Secker & Warburg', 'London');

INSERT INTO books VALUES (1, 'Harry Potter', 1, 1, 1997, '978-0747532743');
INSERT INTO books VALUES (2, '1984', 2, 2, 1949, '978-0451524935');


-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
                            category_id INTEGER PRIMARY KEY,
                            category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
                             product_id INTEGER PRIMARY KEY,
                             product_name TEXT NOT NULL,
                             category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
                        order_id INTEGER PRIMARY KEY,
                        order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

-- Test data for ON DELETE
INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO products_fk VALUES (101, 'Smartphone', 1);

INSERT INTO orders VALUES (500, '2026-10-01');
INSERT INTO order_items VALUES (1, 500, 101, 2);

DELETE FROM orders WHERE order_id = 500;

-- PART 6: Practical Application

CREATE TABLE customers_ecommerce (
                                     customer_id INTEGER PRIMARY KEY,
                                     name TEXT NOT NULL,
                                     email TEXT UNIQUE NOT NULL,
                                     phone TEXT,
                                     registration_date DATE NOT NULL
);

CREATE TABLE products_ecommerce (
                                    product_id INTEGER PRIMARY KEY,
                                    name TEXT NOT NULL,
                                    description TEXT,
                                    price NUMERIC NOT NULL CHECK (price >= 0),
                                    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecommerce (
                                  order_id INTEGER PRIMARY KEY,
                                  customer_id INTEGER REFERENCES customers_ecommerce(customer_id) ON DELETE CASCADE,
                                  order_date DATE NOT NULL,
                                  total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
                                  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details (
                               order_detail_id INTEGER PRIMARY KEY,
                               order_id INTEGER REFERENCES orders_ecommerce(order_id) ON DELETE CASCADE,
                               product_id INTEGER REFERENCES products_ecommerce(product_id) ON DELETE RESTRICT,
                               quantity INTEGER NOT NULL CHECK (quantity > 0),
                               unit_price NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Sample Data (5 records per table)
INSERT INTO customers_ecommerce VALUES
                                    (1, 'Emma Watson', 'emma@example.com', '555-1111', '2026-01-10'),
                                    (2, 'Liam Neeson', 'liam@example.com', '555-2222', '2026-01-15'),
                                    (3, 'Olivia Wilde', 'olivia@example.com', '555-3333', '2026-02-01'),
                                    (4, 'Noah Centineo', 'noah@example.com', '555-4444', '2026-02-12'),
                                    (5, 'Sophia Loren', 'sophia@example.com', '555-5555', '2026-03-01');

INSERT INTO products_ecommerce VALUES
                                   (101, 'Wireless Mouse', 'Ergonomic wireless mouse', 25.99, 150),
                                   (102, 'Mechanical Keyboard', 'RGB backlight mechanical keyboard', 79.99, 80),
                                   (103, 'UltraWide Monitor', '34-inch curved gaming monitor', 399.99, 25),
                                   (104, 'USB-C Hub', '7-in-1 multiports adapter', 35.50, 200),
                                   (105, 'Webcam 1080p', 'HD streaming camera', 49.99, 60);

INSERT INTO orders_ecommerce VALUES
                                 (1001, 1, '2026-04-01', 105.98, 'delivered'),
                                 (1002, 2, '2026-04-03', 399.99, 'shipped'),
                                 (1003, 3, '2026-04-05', 79.99, 'processing'),
                                 (1004, 4, '2026-04-08', 85.49, 'pending'),
                                 (1005, 5, '2026-04-10', 49.99, 'cancelled');

INSERT INTO order_details VALUES
                              (1, 1001, 101, 1, 25.99),
                              (2, 1001, 104, 2, 40.00),
                              (3, 1002, 103, 1, 399.99),
                              (4, 1003, 102, 1, 79.99),
                              (5, 1004, 105, 1, 49.99);
