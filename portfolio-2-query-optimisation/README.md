# Portfolio 2: Query Processing and Optimisation

This portfolio evaluates PostgreSQL query plans for AsterMart's operational and analytical workloads. It uses a deterministic dataset large enough for the planner to make meaningful sequential-scan, join, and index decisions.

## Local PostgreSQL environment

Requirements:

- Docker Desktop or OrbStack with Docker compatibility;
- Docker Compose v2;
- port `5433` available locally, or a different `POSTGRES_PORT` in `.env`.

Start from the repository root:

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

On first start, PostgreSQL runs the Portfolio 1 schema followed by the deterministic seed script. Connect with:

```bash
docker compose exec postgres psql -U astermart_user -d astermart
```

To rebuild the disposable development database from the initialization scripts:

```bash
docker compose down -v
docker compose up -d
```

`docker compose down -v` deletes the local container volume and is appropriate only for this reproducible development dataset.

## Dataset profile

| Relation | Expected rows |
| --- | ---: |
| Branch | 8 |
| Category | 10 |
| Product | 500 |
| Inventory | 4,000 |
| Customer | 20,000 |
| Customer address | 20,000 |
| Sales order | 60,000 |
| Order item | 180,000 |
| Payment | 60,000 |
| Fulfilment | 51,000 |

Names, emails, telephone numbers, order references, and payment references are generated fictional test data. The generator is deterministic so another assessor can reproduce the same row counts and query results.

Query scripts, before/after plans, index definitions, and performance analysis are added in the next focused parts of this milestone.

## Benchmark workload

[`queries/001_business_queries.sql`](queries/001_business_queries.sql) contains five representative operations:

1. retrieve one customer's recent order history;
2. find a branch's processing workload in a reporting period;
3. aggregate units and revenue for a selected product;
4. reconcile successful payments within a completion-time window;
5. identify products at or below their reorder level for a branch.

Each query uses `EXPLAIN (ANALYZE, BUFFERS)`, which executes the statement and reports the actual plan, timings, row counts, and buffer activity. Run the workload from the repository root with:

```bash
./portfolio-2-query-optimisation/scripts/capture_plans.sh
```

The captured unindexed plans are preserved in [`evidence/before-indexes.txt`](evidence/before-indexes.txt). They show sequential scans of all 60,000 orders for Q1 and Q2, a parallel sequential scan of all 180,000 order items for Q3, and a scan of all 60,000 payments for Q4. Q5 already benefits from the inventory primary key's `branch_id` prefix, but still reads 500 branch rows and filters 425 of them after the bitmap scan.
