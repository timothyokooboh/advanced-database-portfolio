#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$repo_root"

psql_cmd="psql -X -v ON_ERROR_STOP=1 -U astermart_user -d astermart"
session_a_output=$(mktemp)
session_b_output=$(mktemp)
cleanup() {
    rm -f "$session_a_output" "$session_b_output"
}
trap cleanup EXIT

# Reset only the two named demonstration orders and their chosen inventory row.
docker compose exec -T postgres $psql_cmd <<'SQL'
SET search_path TO astermart, public;
DELETE FROM order_item
WHERE order_id IN (
    SELECT order_id FROM sales_order
    WHERE order_number IN ('ORD-20261105-900001', 'ORD-20261105-900002')
);
DELETE FROM sales_order
WHERE order_number IN ('ORD-20261105-900001', 'ORD-20261105-900002');
UPDATE inventory
SET quantity_on_hand = 5, updated_at = CURRENT_TIMESTAMP
WHERE branch_id = 8 AND product_id = 499;
SQL

# Session A acquires the row lock first and holds it briefly to make contention visible.
docker compose exec -T postgres $psql_cmd >"$session_a_output" 2>&1 <<'SQL' &
\timing on
SET search_path TO astermart, public;
BEGIN;
SELECT quantity_on_hand AS session_a_locked_quantity
FROM inventory
WHERE branch_id = 8 AND product_id = 499
FOR UPDATE;
SELECT PG_SLEEP(2);
SELECT place_order(
    'ORD-20261105-900001', 1, 8, 1, 'delivery',
    '[{"product_id": 499, "quantity": 4}]'::JSONB
) AS session_a_order_id;
COMMIT;
SQL
session_a_pid=$!

sleep 0.25

# Session B reaches the same row while A holds it. It waits, then rechecks stock.
set +e
docker compose exec -T postgres $psql_cmd >"$session_b_output" 2>&1 <<'SQL'
\timing on
SET search_path TO astermart, public;
SELECT place_order(
    'ORD-20261105-900002', 2, 8, 2, 'delivery',
    '[{"product_id": 499, "quantity": 4}]'::JSONB
) AS session_b_order_id;
SQL
session_b_result=$?
set -e

wait "$session_a_pid"

printf '%s\n' '--- SESSION A: expected COMMIT ---'
sed -n '1,120p' "$session_a_output"
printf '%s\n' '--- SESSION B: expected insufficient-stock rollback ---'
sed -n '1,120p' "$session_b_output"

docker compose exec -T postgres $psql_cmd <<'SQL'
SET search_path TO astermart, public;
SELECT branch_id, product_id, quantity_on_hand AS final_quantity
FROM inventory
WHERE branch_id = 8 AND product_id = 499;
SELECT order_number, order_status, grand_total
FROM sales_order
WHERE order_number IN ('ORD-20261105-900001', 'ORD-20261105-900002')
ORDER BY order_number;
SQL

if [ "$session_b_result" -eq 0 ]; then
    echo 'ERROR: session B unexpectedly succeeded' >&2
    exit 1
fi
