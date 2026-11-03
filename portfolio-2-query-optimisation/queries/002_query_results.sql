-- Compact, reproducible result evidence for the benchmark workload.

\pset pager off
SET search_path TO astermart, public;

\echo 'Q1 result: recent order history for customer 12345'
SELECT order_number, order_status, grand_total, placed_at
FROM sales_order
WHERE customer_id = 12345
ORDER BY placed_at DESC
LIMIT 20;

\echo 'Q2 result summary: branch 3 processing workload in September'
SELECT
    COUNT(*) AS matching_orders,
    MIN(placed_at) AS first_order,
    MAX(placed_at) AS last_order,
    SUM(grand_total) AS workload_value
FROM sales_order
WHERE branch_id = 3
  AND order_status = 'processing'
  AND placed_at >= TIMESTAMPTZ '2026-09-01 00:00:00+01'
  AND placed_at < TIMESTAMPTZ '2026-10-01 00:00:00+01';

\echo 'Q3 result: product 42 sales summary'
SELECT
    oi.product_id,
    COUNT(DISTINCT oi.order_id) AS order_count,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS sales_value
FROM order_item AS oi
JOIN sales_order AS o ON o.order_id = oi.order_id
WHERE oi.product_id = 42
  AND o.order_status <> 'cancelled'
GROUP BY oi.product_id;

\echo 'Q4 result: successful payment reconciliation window'
SELECT provider, COUNT(*) AS payment_count, SUM(amount) AS settled_amount
FROM payment
WHERE payment_status = 'successful'
  AND completed_at >= TIMESTAMPTZ '2026-10-01 00:00:00+01'
  AND completed_at < TIMESTAMPTZ '2026-10-08 00:00:00+01'
GROUP BY provider
ORDER BY settled_amount DESC;

\echo 'Q5 result sample: first 10 low-stock products at branch 3'
SELECT i.product_id, p.sku, p.name, i.quantity_on_hand, i.reorder_level
FROM inventory AS i
JOIN product AS p ON p.product_id = i.product_id
WHERE i.branch_id = 3
  AND i.quantity_on_hand <= i.reorder_level
ORDER BY i.quantity_on_hand, p.sku
LIMIT 10;
