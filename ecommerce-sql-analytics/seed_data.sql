-- =====================================================
-- E-Commerce Sales Analytics Database
-- File: seed_data.sql
-- Purpose: Inserts sample data into all tables
-- Run order: 2nd (run AFTER schema.sql)
-- Note: Run only once on a fresh database
-- =====================================================

-- Categories
INSERT INTO categories (category_id, category_name, description)
VALUES
(1, 'Electronics', 'Electronic gadgets and devices'),
(2, 'Fashion', 'Clothing and accessories'),
(3, 'Home', 'Home appliances and kitchen products'),
(4, 'Sports', 'Fitness and sports equipment');

-- Customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, signup_date, city, country)
VALUES
(1, 'Alice', 'Johnson', 'alice.johnson@example.com', '111-222-3333', '2025-10-15', 'New York', 'USA'),
(2, 'Bob', 'Smith', 'bob.smith@example.com', '444-555-6666', '2025-11-02', 'London', 'UK'),
(3, 'Carol', 'Brown', 'carol.brown@example.com', '777-888-9999', '2025-12-20', 'Toronto', 'Canada'),
(4, 'David', 'Lee', 'david.lee@example.com', '123-123-1234', '2026-01-25', 'Sydney', 'Australia'),
(5, 'Emma', 'Wilson', 'emma.wilson@example.com', '321-321-4321', '2026-02-10', 'Berlin', 'Germany');

-- Products
INSERT INTO products (product_id, product_name, category_id, unit_price, stock_quantity, launch_date)
VALUES
(1, 'Wireless Headphones', 1, 99.99, 100, '2025-09-01'),
(2, 'Smartwatch', 1, 199.99, 80, '2025-09-15'),
(3, 'T-Shirt', 2, 19.99, 200, '2025-08-01'),
(4, 'Jeans', 2, 49.99, 150, '2025-08-10'),
(5, 'Coffee Maker', 3, 79.99, 60, '2025-10-01'),
(6, 'Blender', 3, 59.99, 90, '2025-10-05'),
(7, 'Yoga Mat', 4, 24.99, 120, '2025-07-20'),
(8, 'Dumbbell Set', 4, 89.99, 70, '2025-07-25');

-- Orders
INSERT INTO orders (order_id, customer_id, order_date, status, shipping_city, shipping_country)
VALUES
(1, 1, '2026-01-05 10:30:00', 'delivered', 'New York', 'USA'),
(2, 2, '2026-01-18 14:45:00', 'delivered', 'London', 'UK'),
(3, 3, '2026-02-10 09:15:00', 'delivered', 'Toronto', 'Canada'),
(4, 1, '2026-03-02 16:20:00', 'delivered', 'New York', 'USA'),
(5, 4, '2026-03-15 11:10:00', 'cancelled', 'Sydney', 'Australia'),
(6, 5, '2026-04-20 18:05:00', 'delivered', 'Berlin', 'Germany'),
(7, 2, '2026-05-05 12:40:00', 'delivered', 'London', 'UK'),
(8, 3, '2026-06-11 08:55:00', 'shipped', 'Toronto', 'Canada'),
(9, 1, '2026-07-01 19:25:00', 'pending', 'New York', 'USA'),
(10, 5, '2026-07-15 13:00:00', 'delivered', 'Berlin', 'Germany');

-- Order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_pct)
VALUES
(1, 1, 1, 99.99, 0),
(1, 3, 2, 19.99, 0),
(2, 2, 1, 199.99, 10),
(3, 5, 1, 79.99, 0),
(3, 6, 1, 59.99, 0),
(4, 7, 3, 24.99, 0),
(5, 8, 1, 89.99, 0),
(6, 4, 1, 49.99, 0),
(6, 3, 1, 19.99, 0),
(7, 1, 1, 99.99, 0),
(7, 2, 1, 199.99, 5),
(8, 6, 2, 59.99, 0),
(9, 7, 1, 24.99, 0),
(10, 5, 1, 79.99, 0),
(10, 8, 1, 89.99, 10);

-- Payments (auto-calculated from order totals)
INSERT INTO payments (order_id, payment_method, payment_status, payment_date, amount)
SELECT
    o.order_id,
    CASE
        WHEN o.order_id % 3 = 0 THEN 'paypal'
        WHEN o.order_id % 5 = 0 THEN 'cash_on_delivery'
        ELSE 'card'
    END,
    CASE
        WHEN o.status = 'cancelled' THEN 'failed'
        WHEN o.status = 'pending' THEN 'pending'
        ELSE 'completed'
    END,
    o.order_date + INTERVAL '30 minutes',
    COALESCE(SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100)), 0)
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_id, o.status, o.order_date;

-- Reviews
INSERT INTO reviews (product_id, customer_id, rating, review_text, review_date)
VALUES
(1, 1, 5, 'Excellent sound quality.', '2026-01-10'),
(1, 2, 4, 'Very good, but battery could be better.', '2026-05-08'),
(2, 2, 5, 'Great smartwatch for the price.', '2026-01-25'),
(3, 1, 4, 'Comfortable t-shirt.', '2026-01-12'),
(5, 3, 4, 'Works perfectly for daily use.', '2026-02-15'),
(6, 3, 5, 'Very powerful blender.', '2026-02-18'),
(7, 1, 5, 'Great yoga mat, non-slippery.', '2026-03-05'),
(8, 5, 4, 'Good quality dumbbells.', '2026-07-20');

-- Shipments (auto-generated for shipped/delivered orders)
INSERT INTO shipments (order_id, carrier, shipped_date, delivered_date, shipment_status)
SELECT
    order_id,
    CASE WHEN order_id % 2 = 0 THEN 'FastShip' ELSE 'GlobalExpress' END,
    order_date + INTERVAL '1 day',
    CASE WHEN status = 'delivered' THEN order_date + INTERVAL '3 days' ELSE NULL END,
    CASE
        WHEN status = 'delivered' THEN 'delivered'
        WHEN status = 'shipped' THEN 'in_transit'
        ELSE 'pending'
    END
FROM orders
WHERE status IN ('delivered', 'shipped');

-- Reset ID sequences so future inserts work correctly
SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));
SELECT setval('customers_customer_id_seq', (SELECT MAX(customer_id) FROM customers));
SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));
SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));
SELECT setval('order_items_order_item_id_seq', (SELECT COALESCE(MAX(order_item_id), 1) FROM order_items));
SELECT setval('payments_payment_id_seq', (SELECT COALESCE(MAX(payment_id), 1) FROM payments));
SELECT setval('reviews_review_id_seq', (SELECT COALESCE(MAX(review_id), 1) FROM reviews));
SELECT setval('shipments_shipment_id_seq', (SELECT COALESCE(MAX(shipment_id), 1) FROM shipments));