\set ON_ERROR_STOP on
SET search_path TO astermart, public;

DO $$
DECLARE
    v_order_id BIGINT;
BEGIN
    IF (SELECT quantity_on_hand FROM inventory WHERE branch_id = 8 AND product_id = 499) <> 1 THEN
        RAISE EXCEPTION 'Expected one remaining unit after the concurrency test';
    END IF;

    SELECT order_id INTO v_order_id
    FROM sales_order
    WHERE order_number = 'ORD-20261105-900001';

    IF v_order_id IS NULL THEN
        RAISE EXCEPTION 'Expected Session A order to be committed';
    END IF;

    IF EXISTS (
        SELECT 1 FROM sales_order
        WHERE order_number = 'ORD-20261105-900002'
    ) THEN
        RAISE EXCEPTION 'Session B order should have rolled back';
    END IF;

    IF EXISTS (
        SELECT 1 FROM inventory WHERE quantity_on_hand < 0
    ) THEN
        RAISE EXCEPTION 'Inventory cannot be negative';
    END IF;

    IF (
        SELECT subtotal FROM sales_order WHERE order_id = v_order_id
    ) <> (
        SELECT SUM(line_total) FROM order_item WHERE order_id = v_order_id
    ) THEN
        RAISE EXCEPTION 'Committed order subtotal does not match its lines';
    END IF;
END;
$$;

SELECT 'PASS' AS result,
       'one order committed, competitor rolled back, stock and totals valid' AS checks;
