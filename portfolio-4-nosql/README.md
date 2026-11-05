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
