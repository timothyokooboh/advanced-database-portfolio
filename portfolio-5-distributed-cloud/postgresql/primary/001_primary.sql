CREATE ROLE astermart_replicator
    WITH LOGIN REPLICATION PASSWORD 'replication_dev_password';

CREATE TABLE public.branch_sales_summary (
    summary_id   BIGINT PRIMARY KEY,
    branch_code  VARCHAR(12) NOT NULL,
    summary_date DATE NOT NULL,
    order_count  INTEGER NOT NULL CHECK (order_count >= 0),
    revenue      NUMERIC(16, 2) NOT NULL CHECK (revenue >= 0),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_code, summary_date)
);

INSERT INTO public.branch_sales_summary (
    summary_id, branch_code, summary_date, order_count, revenue
) VALUES
    (1, 'AST-LAG01', DATE '2026-11-01', 142, 18345000.00),
    (2, 'AST-ABJ01', DATE '2026-11-01', 98, 12780000.00),
    (3, 'AST-PHC01', DATE '2026-11-01', 76, 9355000.00);

GRANT CONNECT ON DATABASE astermart_distributed TO astermart_replicator;
GRANT USAGE ON SCHEMA public TO astermart_replicator;
GRANT SELECT ON public.branch_sales_summary TO astermart_replicator;

CREATE PUBLICATION astermart_reporting_pub
    FOR TABLE public.branch_sales_summary;
