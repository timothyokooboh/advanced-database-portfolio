-- Portfolio 2 benchmark workload
-- Run before and after indexes/001_performance_indexes.sql.

\pset pager off
\timing on
SET search_path TO astermart, public;
SET jit TO off;
SET track_io_timing TO on;

\echo 'Q1: Recent order history for one customer'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_number,
    order_status,
    grand_total,
    placed_at
FROM sales_order
WHERE customer_id = 12345
ORDER BY placed_at DESC
LIMIT 20;

\echo 'Q2: Processing workload for a branch and reporting period'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_number,
    customer_id,
    grand_total,
    placed_at
FROM sales_order
WHERE branch_id = 3
  AND order_status = 'processing'
  AND placed_at >= TIMESTAMPTZ '2026-09-01 00:00:00+01'
  AND placed_at < TIMESTAMPTZ '2026-10-01 00:00:00+01'
ORDER BY placed_at DESC;

\echo 'Q3: Sales summary for a selected product'
EXPLAIN (ANALYZE, BUFFERS)
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

\echo 'Q4: Successful payments completed in a reconciliation window'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    provider,
    COUNT(*) AS payment_count,
    SUM(amount) AS settled_amount
FROM payment
WHERE payment_status = 'successful'
  AND completed_at >= TIMESTAMPTZ '2026-10-01 00:00:00+01'
  AND completed_at < TIMESTAMPTZ '2026-10-08 00:00:00+01'
GROUP BY provider
ORDER BY settled_amount DESC;

\echo 'Q5: Low-stock products at one branch'
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    i.product_id,
    p.sku,
    p.name,
    i.quantity_on_hand,
    i.reorder_level
FROM inventory AS i
JOIN product AS p ON p.product_id = i.product_id
WHERE i.branch_id = 3
  AND i.quantity_on_hand <= i.reorder_level
ORDER BY i.quantity_on_hand, p.sku;
