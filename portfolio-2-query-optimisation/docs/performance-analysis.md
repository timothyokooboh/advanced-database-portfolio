# Query Performance Analysis

## Method

The same five statements were executed on PostgreSQL 16.15 with `EXPLAIN (ANALYZE, BUFFERS)`. The baseline was measured after the deterministic seed script and `ANALYZE`, before any custom performance index. The second run followed creation of the five workload-specific indexes and another `ANALYZE`.

Execution time varies with hardware, cache state, and concurrent load, so the figures are evidence from this local run rather than universal guarantees. Plan shape, rows discarded, heap fetches, and buffer use provide the more durable explanation of why each change helps.

## Measured comparison

| Query | Before | After | Execution time | Approx. speed-up | Main reason |
| --- | --- | --- | ---: | ---: | --- |
| Q1 customer history | Sequential scan; 59,997 rows discarded | Index-only scan; 0 heap fetches | 6.972 ms -> 0.081 ms | 86.1x | `(customer_id, placed_at DESC)` satisfies filtering and ordering |
| Q2 branch workload | Sequential scan; 59,900 rows discarded | Index-only range scan; 0 heap fetches | 4.017 ms -> 0.034 ms | 118.1x | Equality keys precede the date range in the composite index |
| Q3 product sales | Parallel scan of 180,000 order items | Index-only scan returning 360 matching lines | 8.029 ms -> 1.118 ms | 7.2x | Product lookup avoids scanning unrelated order lines |
| Q4 reconciliation | Sequential scan; 58,800 rows discarded | Partial index-only scan of the successful time range | 3.205 ms -> 0.198 ms | 16.2x | Failed/pending rows are absent from the partial index |
| Q5 low stock | Primary-key bitmap scan of 500 branch rows; 425 discarded | Partial index-only scan returning 75 low-stock rows | 0.728 ms -> 0.112 ms | 6.5x | The partial index contains only rows at/below reorder level |

The result set was unchanged: Q1 returned 3 orders, Q2 returned 100 orders, Q3 aggregated 360 order lines, Q4 aggregated 1,200 successful payments, and Q5 returned 75 low-stock inventory records.

## Buffer observations

- Q1 reduced execution buffers from 2,188 to 7.
- Q2 reduced execution buffers from 2,185 to 5.
- Q3 reduced combined hit/read buffers from 2,897 to 1,087; most remaining accesses are primary-key lookups for order status.
- Q4 reduced buffers from 910 to 15.
- Q5 reduced buffers from 57 to 20 while retaining a small sequential scan of the 500-row product table, which is reasonable at this size.

## Index cost and trade-offs

| Index | Measured size |
| --- | ---: |
| `idx_inventory_low_stock` | 48 kB |
| `idx_order_item_product_order` | 8,744 kB |
| `idx_payment_successful_completed` | 2,648 kB |
| `idx_sales_order_branch_status_placed` | 5,432 kB |
| `idx_sales_order_customer_placed` | 4,528 kB |

Indexes are not free: they consume storage and add work to inserts, updates, vacuuming, backups, and replication. The order-item index is the largest because it covers 180,000 rows and includes reporting values. It is justified for frequent product-sales reporting but should be monitored with `pg_stat_user_indexes`; an unused production index should be removed after observation.

The two partial indexes control this cost by storing only operationally relevant subsets. The product table remains a sequential scan in Q5 because reading 500 compact rows is cheaper than adding another index solely to cover product names. This illustrates that a sequential scan is not automatically a defect; the optimizer should choose it when the relation is small or a query needs a large proportion of its rows.

## Further optimisation options

- If Q3 becomes dominant, a reporting summary or materialized view could avoid 360 order-header lookups, at the cost of refresh complexity.
- Production measurements should use repeated warm and cold runs, representative hardware, realistic parameter distributions, and `pg_stat_statements` percentiles.
- Partitioning by order date should be considered only after table size and retention requirements justify its operational cost; 60,000 rows do not require it.
- Routine `ANALYZE` and autovacuum health are essential because these plans depend on accurate cardinality statistics and visibility maps.
