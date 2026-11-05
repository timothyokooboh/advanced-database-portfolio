-- Atomic AsterMart order placement with deterministic row locking.

BEGIN;
SET search_path TO astermart, public;

CREATE OR REPLACE FUNCTION place_order(
    p_order_number        VARCHAR(24),
    p_customer_id         BIGINT,
    p_branch_id           BIGINT,
    p_delivery_address_id BIGINT,
    p_fulfilment_method   VARCHAR(10),
    p_items               JSONB
) RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    requested       RECORD;
    v_order_id      BIGINT;
    v_current_price NUMERIC(12, 2);
    v_available     INTEGER;
    v_subtotal      NUMERIC(14, 2) := 0;
BEGIN
    IF JSONB_TYPEOF(p_items) <> 'array' OR JSONB_ARRAY_LENGTH(p_items) = 0 THEN
        RAISE EXCEPTION 'An order must contain at least one item'
            USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM JSONB_TO_RECORDSET(p_items) AS item(product_id BIGINT, quantity INTEGER)
        GROUP BY item.product_id
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'A product may occur only once in an order'
            USING ERRCODE = '22023';
    END IF;

    -- A stable lock order reduces deadlock risk for multi-product orders.
    FOR requested IN
        SELECT item.product_id, item.quantity
        FROM JSONB_TO_RECORDSET(p_items) AS item(product_id BIGINT, quantity INTEGER)
        ORDER BY item.product_id
    LOOP
        IF requested.product_id IS NULL
           OR requested.quantity IS NULL
           OR requested.quantity <= 0 THEN
            RAISE EXCEPTION 'Product and positive quantity are required'
                USING ERRCODE = '22023';
        END IF;

        SELECT p.current_price, i.quantity_on_hand
        INTO v_current_price, v_available
        FROM product AS p
        JOIN inventory AS i ON i.product_id = p.product_id
        WHERE p.product_id = requested.product_id
          AND i.branch_id = p_branch_id
          AND p.is_active
        FOR UPDATE OF i;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Active product % is not stocked at branch %',
                requested.product_id, p_branch_id
                USING ERRCODE = 'P0002';
        END IF;

        IF v_available < requested.quantity THEN
            RAISE EXCEPTION
                'Insufficient stock for product % at branch %: requested %, available %',
                requested.product_id, p_branch_id, requested.quantity, v_available
                USING ERRCODE = 'P0001';
        END IF;

        v_subtotal := v_subtotal + (v_current_price * requested.quantity);
    END LOOP;

    INSERT INTO sales_order (
        order_number,
        customer_id,
        branch_id,
        delivery_address_id,
        order_channel,
        fulfilment_method,
        order_status,
        subtotal
    ) VALUES (
        p_order_number,
        p_customer_id,
        p_branch_id,
        p_delivery_address_id,
        'online',
        p_fulfilment_method,
        'confirmed',
        v_subtotal
    )
    RETURNING order_id INTO v_order_id;

    FOR requested IN
        SELECT item.product_id, item.quantity
        FROM JSONB_TO_RECORDSET(p_items) AS item(product_id BIGINT, quantity INTEGER)
        ORDER BY item.product_id
    LOOP
        SELECT current_price
        INTO v_current_price
        FROM product
        WHERE product_id = requested.product_id;

        INSERT INTO order_item (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, requested.product_id, requested.quantity, v_current_price);

        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand - requested.quantity,
            updated_at = CURRENT_TIMESTAMP
        WHERE branch_id = p_branch_id
          AND product_id = requested.product_id;
    END LOOP;

    RETURN v_order_id;
END;
$$;

COMMENT ON FUNCTION place_order(VARCHAR, BIGINT, BIGINT, BIGINT, VARCHAR, JSONB)
IS 'Atomically creates an order and deducts row-locked branch inventory.';

COMMIT;
