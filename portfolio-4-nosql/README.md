# Portfolio 4: NoSQL and Advanced Data Models

This portfolio implements two MongoDB document collections for the same AsterMart case study:

- `products` is a read-oriented catalogue with category-specific attributes and embedded branch availability;
- `order_events` stores an append-oriented timeline of order lifecycle events and their varying payloads.

PostgreSQL remains authoritative for customers, orders, payments, and inventory transactions. The MongoDB model demonstrates polyglot persistence: data is shaped for catalogue browsing and event-timeline reads, with an explicit synchronization boundary.

## Run locally

From the repository root:

```bash
docker compose up -d mongodb
docker compose ps
```

On first start, MongoDB runs [`mongodb/init/001_catalog_model.js`](mongodb/init/001_catalog_model.js), which creates validated collections, indexes, 500 fictional catalogue documents, and 5,000 fictional order events.

Open a shell:

```bash
docker compose exec mongodb mongosh \
  --username astermart_admin \
  --password astermart_mongo_dev_password \
  --authenticationDatabase admin \
  astermart_catalog
```

For non-default credentials, use the values in the local uncommitted `.env` file.

## Artifacts

- [`mongodb/init/001_catalog_model.js`](mongodb/init/001_catalog_model.js): collections, validation, data, and indexes.
- `mongodb/queries/`: catalogue, availability, aggregation, event timeline, and explain examples.
- `mongodb/tests/`: executable validation of counts, indexes, and document diversity.
- `docs/`: model and suitability analysis.
- `evidence/`: captured local outputs.

## Execute queries and validation

Run the query workload:

```bash
docker compose exec -T mongodb mongosh --quiet \
  --username astermart_admin \
  --password astermart_mongo_dev_password \
  --authenticationDatabase admin \
  --file /dev/stdin astermart_catalog \
  < portfolio-4-nosql/mongodb/queries/001_catalog_queries.js
```

Run the automated model checks with the same command, replacing the redirected file with `portfolio-4-nosql/mongodb/tests/001_validate_model.js`.

The captured evidence shows flexible category attributes, embedded branch availability, category aggregation, an ordered event timeline, strict validation, and indexed access. For the category/price query, MongoDB used `idx_category_price` and examined 32 keys and 32 documents to return 32 matches.

## Evidence

- [`evidence/query-output.txt`](evidence/query-output.txt): representative results and explain statistics.
- [`evidence/validation-output.txt`](evidence/validation-output.txt): executable validation result.
- [`docs/document-model-and-suitability.md`](docs/document-model-and-suitability.md): modelling rationale, consistency boundary, and trade-offs.
