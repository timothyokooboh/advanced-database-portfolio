# Portfolio 3: Transactions and Concurrency

This portfolio demonstrates atomic order placement, commit and rollback behaviour, row-level locking, and prevention of an overselling race in AsterMart's PostgreSQL database.

## Artifacts

- [`sql/001_place_order_function.sql`](sql/001_place_order_function.sql) implements the atomic order workflow.
- [`sql/002_commit_rollback_demo.sql`](sql/002_commit_rollback_demo.sql) demonstrates visible changes inside a transaction and restoration after `ROLLBACK`.
- [`scripts/run_concurrency_demo.sh`](scripts/run_concurrency_demo.sh) launches two competing PostgreSQL sessions.
- `evidence/` contains outputs captured from the local PostgreSQL 16 environment.
- [`docs/transaction-analysis.md`](docs/transaction-analysis.md) explains ACID, isolation, locking, and the observed outcome.

## Install the transaction function

From the repository root with PostgreSQL running:

```bash
docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-3-transactions-concurrency/sql/001_place_order_function.sql
```

The function accepts an order header and a JSON array of product/quantity pairs. It validates the request, locks inventory rows in ascending product order, snapshots catalogue prices, inserts the order and lines, and deducts inventory. An exception aborts the complete statement, so partial orders and partial stock deductions cannot remain.

## Execute the demonstrations

```bash
docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-3-transactions-concurrency/sql/002_commit_rollback_demo.sql

./portfolio-3-transactions-concurrency/scripts/run_concurrency_demo.sh
```

The concurrency script safely resets only two named demonstration orders and one fictional inventory record, starts both sessions, asserts that Session B fails, and prints the final database state. Run its postcondition checks with:

```bash
docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-3-transactions-concurrency/tests/001_validate_transaction_demo.sql
```
