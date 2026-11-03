-- Portfolio 2 indexes derived from the measured AsterMart workload.
-- Execute once after the baseline plans have been captured.

BEGIN;
SET search_path TO astermart, public;

-- Q1: equality on customer followed by newest-first order history.
CREATE INDEX idx_sales_order_customer_placed
    ON sales_order (customer_id, placed_at DESC)
    INCLUDE (order_number, order_status, grand_total);

-- Q2: equality filters first, then the date range/order column.
CREATE INDEX idx_sales_order_branch_status_placed
    ON sales_order (branch_id, order_status, placed_at DESC)
    INCLUDE (order_number, customer_id, grand_total);

-- Q3: locate a product's order lines without scanning the full line table.
CREATE INDEX idx_order_item_product_order
    ON order_item (product_id, order_id)
    INCLUDE (quantity, line_total);

-- Q4: index only the successful subset used during settlement reporting.
CREATE INDEX idx_payment_successful_completed
    ON payment (completed_at)
    INCLUDE (provider, amount)
    WHERE payment_status = 'successful';

-- Q5: index only inventory records that require replenishment attention.
CREATE INDEX idx_inventory_low_stock
    ON inventory (branch_id, quantity_on_hand)
    INCLUDE (product_id, reorder_level)
    WHERE quantity_on_hand <= reorder_level;

ANALYZE;
COMMIT;
