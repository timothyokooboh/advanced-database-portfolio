#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$repo_root"

compose_file="compose.distributed.yaml"
admin_psql="psql -X -v ON_ERROR_STOP=1 -U astermart_admin -d astermart_distributed"

docker compose -f "$compose_file" up -d

for attempt in $(seq 1 30); do
    primary_health=$(docker inspect --format '{{.State.Health.Status}}' astermart-distributed-primary 2>/dev/null || true)
    subscriber_health=$(docker inspect --format '{{.State.Health.Status}}' astermart-distributed-subscriber 2>/dev/null || true)
    if [ "$primary_health" = "healthy" ] && [ "$subscriber_health" = "healthy" ]; then
        break
    fi
    sleep 2
done

if [ "$primary_health" != "healthy" ] || [ "$subscriber_health" != "healthy" ]; then
    echo "Distributed PostgreSQL services did not become healthy" >&2
    exit 1
fi

subscription_exists=$(
    docker compose -f "$compose_file" exec -T postgres-subscriber $admin_psql -Atc \
        "SELECT COUNT(*) FROM pg_subscription WHERE subname = 'astermart_reporting_sub'"
)

if [ "$subscription_exists" = "0" ]; then
    docker compose -f "$compose_file" exec -T postgres-subscriber $admin_psql -c \
        "CREATE SUBSCRIPTION astermart_reporting_sub
         CONNECTION 'host=postgres-primary port=5432 dbname=astermart_distributed user=astermart_replicator password=replication_dev_password application_name=astermart_reporting_sub'
         PUBLICATION astermart_reporting_pub;"
fi

for attempt in $(seq 1 30); do
    subscriber_rows=$(
        docker compose -f "$compose_file" exec -T postgres-subscriber $admin_psql -Atc \
            "SELECT COUNT(*) FROM public.branch_sales_summary"
    )
    if [ "$subscriber_rows" -ge 3 ]; then
        break
    fi
    sleep 1
done

docker compose -f "$compose_file" exec -T postgres-primary $admin_psql <<'SQL'
INSERT INTO public.branch_sales_summary (
    summary_id, branch_code, summary_date, order_count, revenue, updated_at
) VALUES (
    900001, 'AST-ENU01', DATE '2026-11-05', 87, 10875000.00, CURRENT_TIMESTAMP
)
ON CONFLICT (summary_id) DO UPDATE
SET order_count = EXCLUDED.order_count,
    revenue = EXCLUDED.revenue,
    updated_at = CURRENT_TIMESTAMP;
SQL

for attempt in $(seq 1 30); do
    subscriber_revenue=$(
        docker compose -f "$compose_file" exec -T postgres-subscriber $admin_psql -Atc \
            "SELECT revenue FROM public.branch_sales_summary WHERE summary_id = 900001"
    )
    if [ "$subscriber_revenue" = "10875000.00" ]; then
        break
    fi
    sleep 1
done

if [ "$subscriber_revenue" != "10875000.00" ]; then
    echo "Subscriber did not receive the incremental change" >&2
    exit 1
fi

echo "--- PUBLISHER ROWS ---"
docker compose -f "$compose_file" exec -T postgres-primary $admin_psql -c \
    "SELECT summary_id, branch_code, summary_date, order_count, revenue FROM public.branch_sales_summary ORDER BY summary_id"

echo "--- SUBSCRIBER ROWS ---"
docker compose -f "$compose_file" exec -T postgres-subscriber $admin_psql -c \
    "SELECT summary_id, branch_code, summary_date, order_count, revenue FROM public.branch_sales_summary ORDER BY summary_id"

echo "--- SUBSCRIPTION MONITORING ---"
docker compose -f "$compose_file" exec -T postgres-subscriber $admin_psql -c \
    "SELECT subname, received_lsn IS NOT NULL AS receiving, latest_end_lsn IS NOT NULL AS applied, latest_end_time FROM pg_stat_subscription"

echo "--- READ-ONLY ROLE TEST (failure expected) ---"
set +e
docker compose -f "$compose_file" exec -T postgres-subscriber \
    sh -c "PGPASSWORD=reporting_dev_password psql -X -v ON_ERROR_STOP=1 -U astermart_report_reader -d astermart_distributed -c \"INSERT INTO branch_sales_summary VALUES (999999, 'AST-TEST', CURRENT_DATE, 1, 1.00, CURRENT_TIMESTAMP)\""
reader_write_result=$?
set -e

if [ "$reader_write_result" -eq 0 ]; then
    echo "Read-only reporting role unexpectedly wrote to the subscriber" >&2
    exit 1
fi

echo "PASS: initial copy, incremental replication, monitoring, and read-only access verified"
