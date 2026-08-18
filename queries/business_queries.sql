-- =====================================================
-- E-Commerce Sales Analytics Database
-- File: business_queries.sql
-- Purpose: Business and analytics queries
-- Note: Run inside ecommerce_analytics database
-- =====================================================


-- -----------------------------------------------------
-- BASIC BUSINESS QUERIES
-- -----------------------------------------------------

-- 1. Total revenue (excludes cancelled/returned orders)
SELECT ROUND(SUM(line_revenue), 2) AS total_revenue
FROM v_order_details
WHERE order_status NOT IN ('cancelled', 'returned');

-- 2. Monthly revenue
SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(line_revenue), 2) AS revenue
FROM v_order_details
WHERE order_status NOT IN ('cancelled', 'returned')
GROUP BY 1
ORDER BY 1;

-- 3. Top products by revenue
SELECT
    product_name,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_revenue), 2) AS revenue
FROM v_order_details
WHERE order_status NOT IN ('cancelled', 'returned')
GROUP BY product_name
ORDER BY revenue DESC;

-- 4. Revenue by category
SELECT
    category_name,
    ROUND(SUM(line_revenue), 2) AS revenue
FROM v_order_details
WHERE order_status NOT IN ('cancelled', 'returned')
GROUP BY category_name
ORDER BY revenue DESC;

-- 5. Best customers by lifetime value
SELECT
    first_name || ' ' || last_name AS customer_name,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(line_revenue), 2) AS lifetime_value
FROM v_order_details
WHERE order_status NOT IN ('cancelled', 'returned')
GROUP BY first_name, last_name
ORDER BY lifetime_value DESC;

-- 6. Average order value (AOV)
SELECT ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT
        order_id,
        SUM(line_revenue) AS order_total
    FROM v_order_details
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY order_id
) order_totals;


-- -----------------------------------------------------
-- ADVANCED ANALYTICS QUERIES
-- -----------------------------------------------------

-- 7. Month-over-month revenue growth (window function: LAG)
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date)::date AS month,
        SUM(line_revenue) AS revenue
    FROM v_order_details
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS previous_month,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    ) AS growth_pct
FROM monthly_revenue
ORDER BY month;

-- 8. Repeat purchase rate
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM v_order_details
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*),
        2
    ) AS repeat_rate_pct
FROM customer_orders;

-- 9. New customers per month
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM v_order_details
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY customer_id
)
SELECT
    DATE_TRUNC('month', first_order_date)::date AS month,
    COUNT(*) AS new_customers
FROM first_orders
GROUP BY 1
ORDER BY 1;

-- 10. RFM customer segmentation
WITH customer_rfm AS (
    SELECT
        customer_id,
        CURRENT_DATE - MAX(order_date)::date AS recency_days,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(line_revenue) AS monetary
    FROM v_order_details
    WHERE order_status NOT IN ('cancelled', 'returned')
    GROUP BY customer_id
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    CASE
        WHEN recency_days <= 60 AND frequency >= 2 THEN 'Champion'
        WHEN recency_days <= 120 THEN 'Active'
        WHEN frequency >= 2 THEN 'Loyal but sleeping'
        WHEN recency_days > 180 THEN 'At risk'
        ELSE 'New or one-time'
    END AS segment
FROM customer_rfm
ORDER BY monetary DESC;

-- 11. Product rating analysis
SELECT
    p.product_name,
    COUNT(r.review_id) AS reviews,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM products p
LEFT JOIN reviews r
    ON p.product_id = r.product_id
GROUP BY p.product_name
ORDER BY avg_rating DESC NULLS LAST;

-- 12. Order status summary
SELECT
    status,
    COUNT(*) AS number_of_orders
FROM orders
GROUP BY status
ORDER BY number_of_orders DESC;

-- 13. Payment method analysis
SELECT
    payment_method,
    payment_status,
    COUNT(*) AS number_of_payments,
    ROUND(SUM(amount), 2) AS total_amount
FROM payments
GROUP BY payment_method, payment_status
ORDER BY payment_method, payment_status;

-- 14. Delivery performance
SELECT
    o.order_id,
    o.order_date::date AS order_date,
    s.carrier,
    s.shipped_date::date AS shipped_date,
    s.delivered_date::date AS delivered_date,
    s.shipment_status,
    EXTRACT(DAY FROM (s.delivered_date - s.shipped_date)) AS delivery_days
FROM orders o
JOIN shipments s
    ON o.order_id = s.order_id
WHERE o.status = 'delivered'
ORDER BY delivery_days DESC;