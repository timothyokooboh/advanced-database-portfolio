-- Fail fast if the reproducible dataset or optimization artifacts are incomplete.

\set ON_ERROR_STOP on
SET search_path TO astermart, public;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM branch) <> 8 THEN
        RAISE EXCEPTION 'Expected 8 branches';
    END IF;
    IF (SELECT COUNT(*) FROM product) <> 500 THEN
        RAISE EXCEPTION 'Expected 500 products';
    END IF;
    IF (SELECT COUNT(*) FROM customer) <> 20000 THEN
        RAISE EXCEPTION 'Expected 20,000 customers';
    END IF;
    IF (SELECT COUNT(*) FROM sales_order) <> 60000 THEN
        RAISE EXCEPTION 'Expected 60,000 orders';
    END IF;
    IF (SELECT COUNT(*) FROM order_item) <> 180000 THEN
        RAISE EXCEPTION 'Expected 180,000 order items';
    END IF;
    IF (SELECT COUNT(*) FROM payment) <> 60000 THEN
        RAISE EXCEPTION 'Expected 60,000 payments';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sales_order AS o
        JOIN (
            SELECT order_id, SUM(line_total) AS item_total
            FROM order_item
            GROUP BY order_id
        ) AS totals USING (order_id)
        WHERE o.subtotal <> totals.item_total
    ) THEN
        RAISE EXCEPTION 'Order subtotal does not match order items';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM payment AS p
        JOIN sales_order AS o USING (order_id)
        WHERE p.amount <> o.grand_total
    ) THEN
        RAISE EXCEPTION 'Payment amount does not match order total';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM pg_indexes
        WHERE schemaname = 'astermart'
          AND indexname LIKE 'idx_%'
    ) <> 5 THEN
        RAISE EXCEPTION 'Expected five workload-specific indexes';
    END IF;
END;
$$;

SELECT
    'PASS' AS result,
    'row counts, financial totals, and five custom indexes validated' AS checks;
