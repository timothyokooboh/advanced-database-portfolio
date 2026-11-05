# Transaction and Concurrency Analysis

## Transaction boundary

`place_order` performs one logical unit of work: validate requested items, lock inventory, insert the order header and lines, and deduct stock. PostgreSQL runs a function call within the caller's transaction. If any validation, insert, or update raises an exception, the statement is rolled back; a caller using an explicit transaction can then roll back the wider unit of work.

## ACID properties in the implementation

- **Atomicity:** order rows, order items, and inventory deductions either succeed together or are rolled back together. The failed competing request left none of them behind.
- **Consistency:** foreign keys, positive-quantity checks, non-negative inventory checks, unique order numbers, and the function's stock validation move the database only between valid states.
- **Isolation:** `SELECT ... FOR UPDATE` gives the transaction an exclusive row lock on every requested branch/product inventory record. A competing writer waits and then evaluates the newly committed quantity.
- **Durability:** after `COMMIT`, PostgreSQL's write-ahead log makes the successful order durable according to the server's configured durability settings.

## The race without locking

A naive application might execute the following as separate operations in two sessions:

```text
Session A reads 5 units          Session B reads 5 units
Session A decides 4 is allowed  Session B decides 4 is allowed
Session A writes 1              Session B writes 1 or -3
```

Depending on the update expression, this creates a lost update or overselling. A database `CHECK` preventing a negative value can reject one form of overselling, but it cannot by itself make the complete order-and-stock workflow atomic.

## Observed lock behaviour

The test set branch 8/product 499 to five units. Session A began a transaction, selected the row `FOR UPDATE`, and held the lock for about two seconds. Session B called the same order function while A held the row.

Session B waited approximately 1.808 seconds. After A committed a four-unit deduction, B acquired the lock and read the current value of one, not the earlier value of five. Its request for four raised an exception. The final state contained one committed order and one unit of stock.

This is correct behaviour under PostgreSQL's default `READ COMMITTED` isolation level. Each statement sees committed data as of that statement, and a locking read that waits for a concurrent updater rechecks the current row version. The explicit row lock protects the business decision between checking availability and deducting stock.

## Deadlock prevention

An order can contain several products. Two sessions that lock the same products in different orders can deadlock. The function sorts requested `product_id` values before locking them, giving all callers the same lock order. PostgreSQL can detect and abort a deadlock, but deterministic ordering reduces the likelihood.

## Commit and rollback evidence

The separate rollback script reduced an inventory value from 143 to 141 inside a transaction and then issued `ROLLBACK`. A subsequent statement saw 143 again. In the concurrency demonstration, Session A reached `COMMIT`; Session B raised an exception, and PostgreSQL rolled back that statement automatically.

## Limitations and production considerations

- The test deliberately holds a lock with `pg_sleep` only to make contention observable; production code must not add artificial delays.
- Applications should set a suitable `lock_timeout` and translate stock exceptions into user-friendly responses.
- Long transactions increase contention and vacuum pressure, so external payment/network calls should not occur while inventory locks are held.
- Serializable isolation could protect more complex cross-row invariants, but it introduces serialization failures that applications must retry.
- Monitoring `pg_stat_activity`, lock waits, deadlocks, and transaction duration is necessary under real load.
