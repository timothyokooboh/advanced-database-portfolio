CREATE TABLE public.branch_sales_summary (
    summary_id   BIGINT PRIMARY KEY,
    branch_code  VARCHAR(12) NOT NULL,
    summary_date DATE NOT NULL,
    order_count  INTEGER NOT NULL CHECK (order_count >= 0),
    revenue      NUMERIC(16, 2) NOT NULL CHECK (revenue >= 0),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (branch_code, summary_date)
);

CREATE ROLE astermart_report_reader
    WITH LOGIN PASSWORD 'reporting_dev_password';
ALTER ROLE astermart_report_reader SET default_transaction_read_only = on;

GRANT CONNECT ON DATABASE astermart_distributed TO astermart_report_reader;
GRANT USAGE ON SCHEMA public TO astermart_report_reader;
GRANT SELECT ON public.branch_sales_summary TO astermart_report_reader;
