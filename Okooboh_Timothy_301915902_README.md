# MIT 8103 Advanced Database Systems Portfolio Summary

**Student:** Timothy Okooboh

**Student ID:** 301915902

**Case study:** AsterMart Retail & Fulfilment Ltd.

**Repository:** [https://github.com/timothyokooboh/advanced-database-portfolio](https://github.com/timothyokooboh/advanced-database-portfolio)

This repository contains the practical portfolio for **MIT 8103 - Advanced Database Systems**. It applies relational, NoSQL, transactional, optimisation, and distributed database concepts to one consistent simulated organisation.

## Selected organisation

**AsterMart Retail & Fulfilment Ltd.** is a simulated Nigerian multi-branch retailer. Customers can shop online, pay electronically, and request home delivery or branch pickup. Staff manage products, branch inventory, orders, payments, and fulfilment.

The portfolio uses PostgreSQL for structured operational data and MongoDB for data whose shape or access pattern benefits from a document model. All names and records used in the project are fictional.

## Portfolio roadmap

| Portfolio | Focus | Status |
| --- | --- | --- |
| 1 | Database design and modelling | Complete |
| 2 | Query processing and optimisation | Complete |
| 3 | Transactions and concurrency | Complete |
| 4 | NoSQL and advanced data models | Complete |
| 5 | Distributed and cloud databases | Complete |

## Repository structure

```text
advanced-database-portfolio/
|-- portfolio-1-database-design/
|-- portfolio-2-query-optimisation/
|-- portfolio-3-transactions-concurrency/
|-- portfolio-4-nosql/
|-- portfolio-5-distributed-cloud/
`-- README.md
```

Each portfolio directory contains its implementation evidence and a README explaining the design, commands, tests, and observations.

## Final documentation

- [LMS portfolio documentation](output/pdf/Okooboh_Timothy_301915902_Portfolio_Documentation.pdf)
- [Editable summary source](final-documentation/Okooboh_Timothy_301915902_Portfolio_Summary.md).
- [AI use declaration](AI_USE_DECLARATION.md).
- [References](REFERENCES.md).

## Local execution requirements

- Docker Desktop, OrbStack, or another Docker-compatible runtime;
- Docker Compose v2 (`docker compose`);
- a POSIX-compatible shell for the supplied automation scripts;
- available local ports `5433`, `27018`, `5441`, and `5442`.

Run all commands from the extracted project root. No `.env` file is required for the reproducible demonstration because `compose.yaml` contains local development defaults. Optional overrides can be created with:

```bash
cp .env.example .env
```

The `.env` file is ignored by Git. When credentials are overridden, the corresponding values must also be used in manual database-shell commands.

## Start the main databases

Start the PostgreSQL and MongoDB portfolio databases:

```bash
docker compose up -d
docker compose ps
```

On the first start, Docker initializes:

- PostgreSQL 16 with the relational schema and deterministic seed dataset;
- MongoDB 7 with validated collections, indexes, 500 product documents, and 5,000 order-event documents.

The main services are available at PostgreSQL port `5433` and MongoDB port `27018`. Service status should become `healthy` before the verification commands are run.

## Run the portfolio verification

### PostgreSQL design, query optimisation, and dataset checks

```bash
./portfolio-2-query-optimisation/scripts/capture_plans.sh

docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-2-query-optimisation/indexes/001_performance_indexes.sql

docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-2-query-optimisation/tests/001_validate_dataset.sql
```

The first command reports the query workload. The remaining commands apply the workload-specific indexes and validate row counts, totals, constraints, and index presence.

### Transactions and concurrency

```bash
docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-3-transactions-concurrency/sql/001_place_order_function.sql

docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-3-transactions-concurrency/sql/002_commit_rollback_demo.sql

./portfolio-3-transactions-concurrency/scripts/run_concurrency_demo.sh

docker compose exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U astermart_user -d astermart \
  < portfolio-3-transactions-concurrency/tests/001_validate_transaction_demo.sql
```

The concurrency demonstration expects one competing session to commit and the other to fail with insufficient stock.

### MongoDB queries and validation

```bash
docker compose exec -T mongodb mongosh --quiet \
  --username astermart_admin \
  --password astermart_mongo_dev_password \
  --authenticationDatabase admin \
  --file /dev/stdin astermart_catalog \
  < portfolio-4-nosql/mongodb/queries/001_catalog_queries.js

docker compose exec -T mongodb mongosh --quiet \
  --username astermart_admin \
  --password astermart_mongo_dev_password \
  --authenticationDatabase admin \
  --file /dev/stdin astermart_catalog \
  < portfolio-4-nosql/mongodb/tests/001_validate_model.js
```

### Distributed PostgreSQL exercise

Run the isolated logical-replication exercise:

```bash
./portfolio-5-distributed-cloud/scripts/setup_and_verify_replication.sh
```

The script starts the publisher and subscriber, creates the subscription, checks initial and incremental replication, and confirms that the reporting role is read-only.

## Stop or rebuild the environments

Stop the main and distributed services without deleting their volumes:

```bash
docker compose down
docker compose -f compose.distributed.yaml down
```

For a clean rebuild of the disposable demonstration data, remove the corresponding volumes before starting again:

```bash
docker compose down -v
docker compose -f compose.distributed.yaml down -v
docker compose up -d
```

The `-v` commands permanently delete only the Docker volumes created for these local portfolio environments.

## Detailed portfolio guides

- [Portfolio 1: database design and modelling](portfolio-1-database-design/README.md)
- [Portfolio 2: query processing and optimisation](portfolio-2-query-optimisation/README.md)
- [Portfolio 3: transactions and concurrency](portfolio-3-transactions-concurrency/README.md)
- [Portfolio 4: NoSQL and advanced data models](portfolio-4-nosql/README.md)
- [Portfolio 5: distributed and cloud databases](portfolio-5-distributed-cloud/README.md)

Every portfolio README contains its exact commands, expected evidence, and validation steps. Credentials in the Compose files are development-only defaults.
