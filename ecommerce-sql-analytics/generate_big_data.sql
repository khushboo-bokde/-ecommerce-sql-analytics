-- =====================================================
-- E-Commerce Sales Analytics Database
-- File: generate_big_data.sql
-- Purpose: Generates a large realistic dataset
--          (~500 customers, ~5,000 orders, ~10,000+ order items)
-- Run order: 3rd (run AFTER schema.sql and seed_data.sql)
-- IMPORTANT: Run only ONCE on a fresh database
-- =====================================================


-- -----------------------------------------------------
-- 1. Add 500 new customers
-- -----------------------------------------------------
WITH gen AS (
    SELECT
        g,
        1 + floor(random()*10)::int AS loc_idx,
        (ARRAY['James','Mary','John','Patricia','Robert','Jennifer','Michael','Linda','William','Elizabeth','Ahmed','Fatima','Raj','Priya','Chen','Wei','Maria','Jose','Anna','Tom'])[1 + floor(random()*20)::int] AS first_name,
        (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Kumar','Singh','Lee','Wang','Martinez','Anderson','Taylor'])[1 + floor(random()*15)::int] AS last_name
    FROM generate_series(1, 500) g
)
INSERT INTO customers (first_name, last_name, email, signup_date, city, country)
SELECT
    first_name,
    last_name,
    'user' || g || '@example.com',
    DATE '2025-01-01' + floor(random()*540)::int,
    (ARRAY['New York','London','Toronto','Sydney','Berlin','Mumbai','Singapore','Dubai','Paris','Tokyo'])[loc_idx],
    (ARRAY['USA','UK','Canada','Australia','Germany','India','Singapore','UAE','France','Japan'])[loc_idx]
FROM gen;


-- -----------------------------------------------------
-- 2. Add 40 new products
-- -----------------------------------------------------
INSERT INTO products (product_name, category_id, unit_price, stock_quantity, launch_date)
SELECT
    (ARRAY['Pro','Ultra','Mini','Max','Plus'])[1 + floor(random()*5)::int]
    || ' ' ||
    (ARRAY['Speaker','Charger','Jacket','Sneakers','Lamp','Kettle','Gloves','Backpack'])[1 + floor(random()*8)::int],
    1 + floor(random()*4)::int,
    round((10 + random()*190)::numeric, 2),
    50 + floor(random()*200)::int,
    DATE '2025-01-01' + floor(random()*540)::int
FROM generate_series(1, 40) g;


-- -----------------------------------------------------
-- 3. Add 5,000 new orders
-- -----------------------------------------------------
INSERT INTO orders (customer_id, order_date, status, shipping_city, shipping_country)
SELECT
    1 + floor(random()*505)::int,
    TIMESTAMP '2025-01-01 08:00:00'
        + floor(random()*576)::int * INTERVAL '1 day'
        + floor(random()*14)::int * INTERVAL '1 hour'
        + floor(random()*60)::int * INTERVAL '1 minute',
    (ARRAY['delivered','delivered','delivered','delivered','delivered','shipped','pending','cancelled','returned'])[1 + floor(random()*9)::int],
    (ARRAY['New York','London','Toronto','Sydney','Berlin','Mumbai','Singapore','Dubai','Paris','Tokyo'])[1 + floor(random()*10)::int],
    (ARRAY['USA','UK','Canada','Australia','Germany','India','Singapore','UAE','France','Japan'])[1 + floor(random()*10)::int]
FROM generate_series(1, 5000) g;


-- -----------------------------------------------------
-- 4. Add order items for the new orders (~10,000+ rows)
--    (order_id > 10 skips the original sample orders)
-- -----------------------------------------------------
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct)
SELECT
    o.order_id,
    p.product_id,
    1 + floor(random()*3)::int,
    p.unit_price,
    (ARRAY[0, 0, 0, 0, 5, 10])[1 + floor(random()*6)::int]
FROM orders o
CROSS JOIN LATERAL (
    SELECT pr.product_id, pr.unit_price
    FROM products pr
    ORDER BY random()
    LIMIT 1 + floor(random()*3)::int
) p
WHERE o.order_id > 10;


-- -----------------------------------------------------
-- 5. Add payments for the new orders
-- -----------------------------------------------------
INSERT INTO payments (order_id, payment_method, payment_status, payment_date, amount)
SELECT
    o.order_id,
    (ARRAY['card','card','card','paypal','upi','bank_transfer'])[1 + floor(random()*6)::int],
    CASE
        WHEN o.status = 'cancelled' THEN 'failed'
        WHEN o.status = 'pending' THEN 'pending'
        ELSE 'completed'
    END,
    o.order_date + INTERVAL '30 minutes',
    (
        SELECT COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 0)
        FROM order_items oi
        WHERE oi.order_id = o.order_id
    )
FROM orders o
WHERE o.order_id > 10;


-- -----------------------------------------------------
-- 6. Add shipments for shipped/delivered new orders
-- -----------------------------------------------------
INSERT INTO shipments (order_id, carrier, shipped_date, delivered_date, shipment_status)
SELECT
    o.order_id,
    (ARRAY['FastShip','GlobalExpress','QuickPost'])[1 + floor(random()*3)::int],
    o.order_date + INTERVAL '1 day',
    CASE
        WHEN o.status = 'delivered'
            THEN o.order_date + (2 + floor(random()*4)::int) * INTERVAL '1 day'
        ELSE NULL
    END,
    CASE
        WHEN o.status = 'delivered' THEN 'delivered'
        WHEN o.status = 'shipped' THEN 'in_transit'
        ELSE 'pending'
    END
FROM orders o
WHERE o.order_id > 10
  AND o.status IN ('delivered', 'shipped');


-- -----------------------------------------------------
-- 7. Add 400 reviews
-- -----------------------------------------------------
INSERT INTO reviews (product_id, customer_id, rating, review_text, review_date)
SELECT
    1 + floor(random()*48)::int,
    1 + floor(random()*505)::int,
    1 + floor(random()*5)::int,
    (ARRAY['Great product!','Good value for money.','Average quality.','Not satisfied.','Excellent, highly recommended.'])[1 + floor(random()*5)::int],
    DATE '2025-06-01' + floor(random()*425)::int
FROM generate_series(1, 400) g
ON CONFLICT DO NOTHING;


-- -----------------------------------------------------
-- 8. Verify the generated data
-- -----------------------------------------------------
SELECT 'categories' AS table_name, COUNT(*) FROM categories
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL SELECT 'shipments', COUNT(*) FROM shipments;