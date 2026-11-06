# MIT 8103 Advanced Database Systems Portfolio Summary

**Student:** Timothy Okooboh  
**Student ID:** 301915902  
**Case study:** AsterMart Retail & Fulfilment Ltd.  
**Repository:** https://github.com/timothyokooboh/advanced-database-portfolio

## Organisation and technical approach

AsterMart is a simulated Nigerian multi-branch retailer with online ordering, branch pickup, delivery, electronic payment, and stock management. PostgreSQL is the transactional system of record. MongoDB supplies read-oriented product catalogue and event-timeline models. Docker Compose makes the portfolio reproducible locally.

## Portfolio activities

### 1. Database design and modelling

The design defines ten normalized relations for branches, categories, products, inventory, customers, addresses, orders, order items, payments, and fulfilment. The ER model records cardinalities and keys; PostgreSQL constraints enforce natural identifiers, ownership, controlled statuses, positive values, and delivery-address rules. The schema is in 3NF, while order-line prices are intentional historical snapshots.

### 2. Query processing and optimisation

A deterministic dataset contains 20,000 customers, 60,000 orders, 180,000 order items, and 60,000 payments. Five business queries were executed with `EXPLAIN (ANALYZE, BUFFERS)` before and after workload-specific indexes. The largest measured improvement changed a 60,000-row branch-workload scan from 4.017 ms to a 0.034 ms index-only scan. Plans, results, buffer counts, index sizes, and trade-offs are retained in the repository.

### 3. Transactions and concurrency

The `place_order` function locks inventory rows in deterministic product order, validates stock, inserts the header and lines, and deducts inventory atomically. In a two-session test, both sessions requested four of five available units. Session A committed; Session B waited, observed the new balance of one, and rolled back with an insufficient-stock error. A separate rollback test restored an inventory value from 141 to 143.

### 4. NoSQL and advanced data models

MongoDB stores 500 product catalogue documents with flexible category attributes and embedded branch availability, plus 5,000 append-oriented order events. Strict JSON Schema validators reject malformed documents. Indexes support SKU identity, category/price browsing, tags, branch availability, text search, and ordered timelines. An explain run used `idx_category_price`, examining 32 keys and 32 documents for 32 results.

### 5. Distributed and cloud database exercise

Two PostgreSQL containers implement logical replication from an operational publisher to a reporting subscriber. Initial data and a subsequent branch-summary change were replicated; publisher and subscriber values matched and `pg_stat_subscription` showed active receive/apply positions. A read-only reporting account could query the subscriber but its insert was rejected. The analysis distinguishes asynchronous reporting replication from automatic high-availability failover and proposes multi-zone deployment, monitored lag, backups, and branch-oriented distribution only when scale justifies it.

## Technical reflection

This portfolio showed me that advanced database design is not only about creating tables. Constraints and normalization establish correctness, but workload evidence determines useful indexes, and transaction boundaries determine whether a correct schema remains correct under concurrency. The first seed run failed because a temporary discounted order violated the total constraint; executing the scripts exposed this early. The scarce-stock test made row locks and isolation concrete because the second session waited and rechecked committed stock instead of overselling.

I also learned to choose models by access pattern. MongoDB simplified variable product attributes and event payloads, but duplicating availability creates a consistency boundary, so PostgreSQL must remain authoritative during checkout. Logical replication improved reporting isolation and read availability, yet it did not remove the need for backups, schema coordination, lag monitoring, or planned failover. My main lesson is that design claims should be supported by repeatable scripts, measured plans, negative tests, and documented limitations.

## Verification highlights

- PostgreSQL and MongoDB services run locally through Docker Compose.
- Automated tests validated row counts, financial totals, schema rules, indexes, rollback postconditions, and NoSQL document diversity.
- Evidence files preserve query results, plans, concurrency output, validation output, and replication status.
- The repository uses one case study consistently and contains focused progressive commits.

## AI use declaration

OpenAI Codex assisted with milestone planning, drafts of code/documentation, testing ideas, and formatting. All scripts were executed locally; outputs and database states were inspected, and generated material was corrected when tests exposed problems. Official documentation was used for technical claims. I remain responsible for reviewing, understanding, explaining, and submitting the work. The full declaration is included in the repository.

## References

1. PostgreSQL Global Development Group, *PostgreSQL 16 Documentation*, https://www.postgresql.org/docs/16/.
2. PostgreSQL Global Development Group, *Logical Replication*, https://www.postgresql.org/docs/16/logical-replication.html.
3. MongoDB, Inc., *Data Modeling*, https://www.mongodb.com/docs/manual/data-modeling/.
4. MongoDB, Inc., *Schema Validation*, https://www.mongodb.com/docs/manual/core/schema-validation/.
