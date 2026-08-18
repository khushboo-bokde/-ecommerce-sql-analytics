-- =====================================================
-- E-Commerce Sales Analytics Database
-- File: schema.sql
-- Database: PostgreSQL
-- Purpose: Creates all tables, indexes, and views
-- Run order: 1st (run before seed_data.sql)
-- =====================================================

DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS shipments CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- -----------------------------------------------------
-- Table 1: categories
-- -----------------------------------------------------
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- -----------------------------------------------------
-- Table 2: customers
-- -----------------------------------------------------
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),
    signup_date DATE NOT NULL DEFAULT CURRENT_DATE,
    city VARCHAR(100),
    country VARCHAR(100)
);

-- -----------------------------------------------------
-- Table 3: products
-- -----------------------------------------------------
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    launch_date DATE
);

-- -----------------------------------------------------
-- Table 4: orders
-- -----------------------------------------------------
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'shipped', 'delivered', 'cancelled', 'returned')),
    shipping_city VARCHAR(100),
    shipping_country VARCHAR(100)
);

-- -----------------------------------------------------
-- Table 5: order_items
-- -----------------------------------------------------
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    discount_pct NUMERIC(5,2) NOT NULL DEFAULT 0
        CHECK (discount_pct BETWEEN 0 AND 100),
    UNIQUE (order_id, product_id)
);

-- -----------------------------------------------------
-- Table 6: payments
-- -----------------------------------------------------
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE REFERENCES orders(order_id),
    payment_method VARCHAR(30) NOT NULL
        CHECK (payment_method IN ('card', 'paypal', 'cash_on_delivery', 'upi', 'bank_transfer')),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_date TIMESTAMP,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0)
);

-- -----------------------------------------------------
-- Table 7: reviews
-- -----------------------------------------------------
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_date DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (product_id, customer_id)
);

-- -----------------------------------------------------
-- Table 8: shipments
-- -----------------------------------------------------
CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE REFERENCES orders(order_id),
    carrier VARCHAR(100),
    shipped_date TIMESTAMP,
    delivered_date TIMESTAMP,
    shipment_status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (shipment_status IN ('pending', 'shipped', 'in_transit', 'delivered', 'returned', 'lost'))
);

-- -----------------------------------------------------
-- Indexes for performance
-- -----------------------------------------------------
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);

-- -----------------------------------------------------
-- Analytics view (main reporting table)
-- -----------------------------------------------------
CREATE OR REPLACE VIEW v_order_details AS
SELECT
    o.order_id,
    o.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.city AS customer_city,
    c.country AS customer_country,
    o.order_date,
    o.status AS order_status,
    p.product_id,
    p.product_name,
    cat.category_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100) AS line_revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN categories cat
    ON p.category_id = cat.category_id
JOIN customers c
    ON o.customer_id = c.customer_id; 

# CREATE VIEW 

CREATE OR REPLACE VIEW v_sales AS
SELECT
    v.*,
    p.payment_method,
    DATE_TRUNC('month', v.order_date)::date AS order_month
FROM v_order_details v
LEFT JOIN payments p
    ON v.order_id = p.order_id
WHERE v.order_status NOT IN ('cancelled', 'returned');