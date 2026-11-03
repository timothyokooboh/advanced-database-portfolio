-- MIT 8103 Advanced Database Systems
-- Portfolio 2: deterministic AsterMart performance dataset
-- All people, contacts, references, and transactions are fictional.

BEGIN;
SET search_path TO astermart, public;

INSERT INTO branch (
    branch_code, name, phone, email, address_line, city, state
) VALUES
    ('AST-LAG01', 'AsterMart Ikeja', '+2348000000001', 'ikeja@astermart.example', '12 Allen Avenue', 'Ikeja', 'Lagos'),
    ('AST-LAG02', 'AsterMart Lekki', '+2348000000002', 'lekki@astermart.example', '18 Admiralty Way', 'Lekki', 'Lagos'),
    ('AST-ABJ01', 'AsterMart Wuse', '+2348000000003', 'wuse@astermart.example', '24 Aminu Kano Crescent', 'Abuja', 'FCT'),
    ('AST-KAN01', 'AsterMart Nassarawa', '+2348000000004', 'kano@astermart.example', '6 Zoo Road', 'Kano', 'Kano'),
    ('AST-PHC01', 'AsterMart GRA', '+2348000000005', 'portharcourt@astermart.example', '31 Aba Road', 'Port Harcourt', 'Rivers'),
    ('AST-IBD01', 'AsterMart Bodija', '+2348000000006', 'ibadan@astermart.example', '15 Awolowo Avenue', 'Ibadan', 'Oyo'),
    ('AST-ENU01', 'AsterMart Independence Layout', '+2348000000007', 'enugu@astermart.example', '9 Presidential Road', 'Enugu', 'Enugu'),
    ('AST-BEN01', 'AsterMart Ring Road', '+2348000000008', 'benin@astermart.example', '42 Sapele Road', 'Benin City', 'Edo');

INSERT INTO category (name, description) VALUES
    ('Groceries', 'Packaged food and cooking ingredients'),
    ('Beverages', 'Non-alcoholic drinks and water'),
    ('Fresh Food', 'Fresh produce and refrigerated food'),
    ('Household', 'Cleaning and household supplies'),
    ('Personal Care', 'Personal hygiene and grooming'),
    ('Baby Care', 'Baby food, nappies, and care items'),
    ('Health', 'Over-the-counter wellness products'),
    ('Electronics', 'Small consumer electronics'),
    ('Stationery', 'Office and school supplies'),
    ('Pet Care', 'Food and supplies for domestic pets');

INSERT INTO product (category_id, sku, name, description, current_price)
SELECT
    ((g - 1) % 10) + 1,
    'AST-PRD-' || LPAD(g::TEXT, 5, '0'),
    CASE ((g - 1) % 10) + 1
        WHEN 1 THEN 'Grocery Item '
        WHEN 2 THEN 'Beverage Item '
        WHEN 3 THEN 'Fresh Food Item '
        WHEN 4 THEN 'Household Item '
        WHEN 5 THEN 'Personal Care Item '
        WHEN 6 THEN 'Baby Care Item '
        WHEN 7 THEN 'Health Item '
        WHEN 8 THEN 'Electronics Item '
        WHEN 9 THEN 'Stationery Item '
        ELSE 'Pet Care Item '
    END || LPAD(g::TEXT, 3, '0'),
    'Fictional AsterMart catalogue product ' || g,
    (500 + ((g * 137) % 49500))::NUMERIC(12, 2)
FROM generate_series(1, 500) AS g;

INSERT INTO inventory (
    branch_id, product_id, quantity_on_hand, reorder_level, last_counted_at
)
SELECT
    b.branch_id,
    p.product_id,
    ((b.branch_id * 17 + p.product_id * 13) % 240)::INTEGER,
    (20 + ((b.branch_id + p.product_id) % 30))::INTEGER,
    TIMESTAMPTZ '2026-10-31 18:00:00+01' - ((p.product_id % 14) * INTERVAL '1 day')
FROM branch AS b
CROSS JOIN product AS p;

INSERT INTO customer (
    first_name, last_name, email, phone
)
SELECT
    'Customer' || LPAD(g::TEXT, 5, '0'),
    'Test' || LPAD(((g * 7) % 20000 + 1)::TEXT, 5, '0'),
    'customer' || LPAD(g::TEXT, 5, '0') || '@example.test',
    '+23470' || LPAD(g::TEXT, 8, '0')
FROM generate_series(1, 20000) AS g;

INSERT INTO customer_address (
    customer_id, label, address_line_1, city, state, postal_code, is_default
)
SELECT
    c.customer_id,
    'Home',
    (100 + c.customer_id) || ' Example Street',
    CASE ((c.customer_id - 1) % 8) + 1
        WHEN 1 THEN 'Ikeja'
        WHEN 2 THEN 'Lekki'
        WHEN 3 THEN 'Abuja'
        WHEN 4 THEN 'Kano'
        WHEN 5 THEN 'Port Harcourt'
        WHEN 6 THEN 'Ibadan'
        WHEN 7 THEN 'Enugu'
        ELSE 'Benin City'
    END,
    CASE ((c.customer_id - 1) % 8) + 1
        WHEN 1 THEN 'Lagos'
        WHEN 2 THEN 'Lagos'
        WHEN 3 THEN 'FCT'
        WHEN 4 THEN 'Kano'
        WHEN 5 THEN 'Rivers'
        WHEN 6 THEN 'Oyo'
        WHEN 7 THEN 'Enugu'
        ELSE 'Edo'
    END,
    LPAD((100000 + (c.customer_id % 900000))::TEXT, 6, '0'),
    TRUE
FROM customer AS c;

INSERT INTO sales_order (
    order_number,
    customer_id,
    branch_id,
    delivery_address_id,
    order_channel,
    fulfilment_method,
    order_status,
    subtotal,
    delivery_fee,
    discount_amount,
    placed_at,
    updated_at
)
SELECT
    'ORD-' || TO_CHAR(order_time, 'YYYYMMDD') || '-' || LPAD(g::TEXT, 6, '0'),
    customer_id,
    branch_id,
    CASE WHEN g % 4 = 0 THEN NULL ELSE customer_id END,
    CASE WHEN g % 10 = 0 THEN 'in_store' ELSE 'online' END,
    CASE WHEN g % 4 = 0 THEN 'pickup' ELSE 'delivery' END,
    CASE
        WHEN g % 20 = 0 THEN 'cancelled'
        WHEN g % 10 = 1 THEN 'pending'
        WHEN g % 10 IN (2, 3) THEN 'processing'
        WHEN g % 10 IN (4, 5) THEN 'ready'
        WHEN g % 10 IN (6, 7) THEN 'dispatched'
        ELSE 'completed'
    END,
    CASE WHEN g % 12 = 0 THEN 1000 ELSE 0 END,
    CASE WHEN g % 4 = 0 THEN 0 ELSE 1500 + ((g % 4) * 250) END,
    CASE WHEN g % 12 = 0 THEN 1000 ELSE 0 END,
    order_time,
    order_time + INTERVAL '2 hours'
FROM (
    SELECT
        g,
        ((g - 1) % 20000) + 1 AS customer_id,
        ((g - 1) % 8) + 1 AS branch_id,
        TIMESTAMPTZ '2026-01-01 08:00:00+01'
            + ((g - 1) % 300) * INTERVAL '1 day'
            + ((g * 7) % 720) * INTERVAL '1 minute' AS order_time
    FROM generate_series(1, 60000) AS g
) AS generated_orders;

INSERT INTO order_item (order_id, product_id, quantity, unit_price)
SELECT
    o.order_id,
    p.product_id,
    1 + ((o.order_id + item_position) % 4)::INTEGER,
    p.current_price
FROM sales_order AS o
CROSS JOIN generate_series(1, 3) AS item_position
JOIN product AS p
    ON p.product_id = ((o.order_id * 7 + item_position * 31) % 500) + 1;

UPDATE sales_order AS o
SET subtotal = totals.subtotal
FROM (
    SELECT order_id, SUM(line_total) AS subtotal
    FROM order_item
    GROUP BY order_id
) AS totals
WHERE totals.order_id = o.order_id;

INSERT INTO payment (
    order_id,
    provider,
    provider_reference,
    amount,
    payment_status,
    payment_method,
    attempted_at,
    completed_at
)
SELECT
    o.order_id,
    CASE o.order_id % 3
        WHEN 0 THEN 'Paystack Demo'
        WHEN 1 THEN 'Flutterwave Demo'
        ELSE 'AsterMart POS Demo'
    END,
    'PAY-DEMO-' || LPAD(o.order_id::TEXT, 8, '0'),
    o.grand_total,
    CASE
        WHEN o.order_status = 'pending' THEN 'pending'
        WHEN o.order_status = 'cancelled' THEN 'failed'
        ELSE 'successful'
    END,
    CASE o.order_id % 4
        WHEN 0 THEN 'transfer'
        WHEN 1 THEN 'card'
        WHEN 2 THEN 'wallet'
        ELSE 'cash'
    END,
    o.placed_at + INTERVAL '2 minutes',
    CASE
        WHEN o.order_status IN ('pending', 'cancelled') THEN NULL
        ELSE o.placed_at + INTERVAL '3 minutes'
    END
FROM sales_order AS o;

INSERT INTO fulfilment (
    order_id,
    fulfilment_status,
    tracking_reference,
    ready_at,
    dispatched_at,
    completed_at,
    updated_at
)
SELECT
    o.order_id,
    CASE o.order_status
        WHEN 'processing' THEN 'picking'
        WHEN 'ready' THEN 'ready'
        WHEN 'dispatched' THEN 'dispatched'
        WHEN 'completed' THEN 'completed'
        ELSE 'awaiting'
    END,
    CASE
        WHEN o.fulfilment_method = 'delivery'
            THEN 'TRK-DEMO-' || LPAD(o.order_id::TEXT, 8, '0')
        ELSE NULL
    END,
    CASE
        WHEN o.order_status IN ('ready', 'dispatched', 'completed')
            THEN o.placed_at + INTERVAL '4 hours'
        ELSE NULL
    END,
    CASE
        WHEN o.order_status IN ('dispatched', 'completed')
             AND o.fulfilment_method = 'delivery'
            THEN o.placed_at + INTERVAL '6 hours'
        ELSE NULL
    END,
    CASE
        WHEN o.order_status = 'completed'
            THEN o.placed_at + INTERVAL '10 hours'
        ELSE NULL
    END,
    o.updated_at
FROM sales_order AS o
WHERE o.order_status NOT IN ('pending', 'cancelled');

ANALYZE;
COMMIT;
