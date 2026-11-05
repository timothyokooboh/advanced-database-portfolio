-- Demonstrate that a rolled-back update leaves no persistent inventory change.

\pset pager off
\set ON_ERROR_STOP on
SET search_path TO astermart, public;

\echo 'Value before transaction'
SELECT branch_id, product_id, quantity_on_hand
FROM inventory
WHERE branch_id = 8 AND product_id = 499;

BEGIN;
UPDATE inventory
SET quantity_on_hand = quantity_on_hand - 2
WHERE branch_id = 8 AND product_id = 499;

\echo 'Value visible inside the transaction before rollback'
SELECT branch_id, product_id, quantity_on_hand
FROM inventory
WHERE branch_id = 8 AND product_id = 499;
ROLLBACK;

\echo 'Value after rollback - restored to the original value'
SELECT branch_id, product_id, quantity_on_hand
FROM inventory
WHERE branch_id = 8 AND product_id = 499;
