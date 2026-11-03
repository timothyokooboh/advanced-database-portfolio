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
