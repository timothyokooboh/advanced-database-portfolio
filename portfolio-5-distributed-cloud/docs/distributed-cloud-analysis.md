# Distributed and Cloud Database Analysis

## Implemented exercise

The local exercise runs two independent PostgreSQL 16 containers. `postgres-primary` publishes `branch_sales_summary`; `postgres-subscriber` subscribes through a dedicated login with replication and table-level `SELECT` privileges. PostgreSQL copied three existing rows during initial synchronization and then delivered an incremental fourth row through the replication stream.

The publisher and subscriber each returned the same four keys and financial values. `pg_stat_subscription` reported an active receiver and applied end LSN. A reporting login on the subscriber had `SELECT` only and `default_transaction_read_only=on`; its test insert failed.

## Replication design

Logical replication was selected because AsterMart may distribute selected reporting tables rather than byte-for-byte copies of the entire operational cluster. A publication represents the chosen change set, while a subscription defines the downstream connection and consumes it through a replication slot. PostgreSQL performs an initial table copy and then streams subsequent data changes.

The exercise uses a primary key as replica identity, allowing updates and deletes to identify the target row. Monitoring uses `pg_stat_subscription`; production monitoring should also alert on receive/apply lag, inactive workers, retained WAL, slot growth, and subscriber conflicts.

## Consistency and availability

Operational order placement remains on the primary and preserves transactional consistency. Reporting reads are served from an asynchronously updated subscriber and are therefore eventually consistent: immediately after a primary commit, a report can briefly show an older value.

During a network partition, the reporting service can remain available with its last applied data, but it must show a freshness timestamp. The platform should not route inventory deductions to the reporting node. For checkout, AsterMart prefers consistency over accepting writes on disconnected nodes because conflicting stock deductions could oversell products.

The subscriber improves read availability and isolates analytical workload, but this logical-replication demonstration is not automatic high availability. Promotion, client routing, sequence repair, recovery-point validation, and split-brain prevention require an orchestrated failover design. A production transactional database should additionally use managed multi-zone or physical streaming replication with tested failover and backups.

## Distribution and sharding proposal

If AsterMart grows beyond one writer's capacity, branch-owned operational data can be distributed by a stable `region_id` or branch group. Co-locating inventory and fulfilment rows for the same branch keeps the common stock transaction within one shard. A routing catalogue maps branches to shards.

Customer and product reference data may be replicated to each region, while globally unique order identifiers avoid collisions. Cross-region reports should use an analytical store or federated aggregation rather than synchronous distributed joins on the checkout path. Rebalancing, hotspots, cross-shard customer orders, and global uniqueness make sharding an operational cost; it should follow measured need, not be introduced for the current 60,000-order dataset.

## Cloud deployment design

A production design would place the PostgreSQL writer and synchronous/managed standby across separate availability zones, add one or more asynchronous read replicas for reporting, and use automated backups with point-in-time recovery. Connections and credentials belong in a secret manager; transport encryption, private networking, least-privilege roles, audit logs, patching, and restore drills are required.

MongoDB catalogue/event projections can use a managed replica set distributed across failure domains. Catalogue services may read from secondaries when bounded staleness is acceptable, but checkout must revalidate PostgreSQL inventory. Change-data capture or an outbox consumer should update projections idempotently.

## Limitations and operational risks

PostgreSQL logical replication does not replicate schema/DDL or sequence state, so migrations must be coordinated and promotion requires sequence reconciliation. A constraint or permission conflict on the subscriber can stop replication until corrected. A forgotten inactive slot can retain WAL and exhaust publisher storage. Backups remain necessary because replication also propagates unwanted changes; a replica is not a backup.

The demo uses development passwords, unencrypted container networking, one host, and a small table. It proves configuration and data flow, not multi-host fault tolerance or production security.

## References

1. PostgreSQL Global Development Group. [Logical Replication - Quick Setup](https://www.postgresql.org/docs/16/logical-replication-quick-setup.html), PostgreSQL 16 documentation.
2. PostgreSQL Global Development Group. [Publication](https://www.postgresql.org/docs/16/logical-replication-publication.html), PostgreSQL 16 documentation.
3. PostgreSQL Global Development Group. [Subscription](https://www.postgresql.org/docs/16/logical-replication-subscription.html), PostgreSQL 16 documentation.
4. PostgreSQL Global Development Group. [Logical Replication Restrictions](https://www.postgresql.org/docs/16/logical-replication-restrictions.html), PostgreSQL 16 documentation.
5. PostgreSQL Global Development Group. [Logical Replication Monitoring](https://www.postgresql.org/docs/16/logical-replication-monitoring.html), PostgreSQL 16 documentation.
6. MongoDB, Inc. [Replication](https://www.mongodb.com/docs/manual/replication/), MongoDB documentation.
