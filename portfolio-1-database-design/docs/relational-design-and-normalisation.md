# Relational Design and Normalisation

## Relational schema summary

| Relation | Primary key | Candidate/alternate keys | Important foreign keys and constraints |
| --- | --- | --- | --- |
| `branch` | `branch_id` | `branch_code`, `email` | Branch code format and lowercase email checks |
| `category` | `category_id` | `name` | Non-blank category name |
| `product` | `product_id` | `sku` | `category_id` references `category`; positive catalogue price |
| `inventory` | (`branch_id`, `product_id`) | Composite primary key | Both columns are foreign keys; quantities and reorder levels are non-negative |
| `customer` | `customer_id` | `email`, `phone` | Non-blank names and lowercase email |
| `customer_address` | `address_id` | (`address_id`, `customer_id`) | `customer_id` references the owner; composite key supports ownership validation on orders |
| `sales_order` | `order_id` | `order_number` | References customer, branch, and the selected customer's address; controlled status and amount checks |
| `order_item` | `order_item_id` | (`order_id`, `product_id`) | References order and product; positive quantity and historical unit price |
| `payment` | `payment_id` | `provider_reference` | References order; controlled status/method and completion-time consistency |
| `fulfilment` | `fulfilment_id` | `order_id`, `tracking_reference` | One-to-zero-or-one relationship with order; controlled status and timestamp ordering |

Surrogate numeric primary keys give stable, narrow references. Natural business identifiers remain protected with `UNIQUE` constraints so duplicates cannot enter through another application path.

Foreign keys use PostgreSQL's default restrictive behaviour. Deleting customers, products, branches, or orders that still have dependent records is intentionally rejected. Operational records should normally be deactivated or retained for audit rather than cascade-deleted.

## Functional dependencies

The main dependencies used during decomposition are:

```text
branch_id -> branch_code, name, phone, email, address_line, city, state, is_active
category_id -> name, description, is_active
product_id -> category_id, sku, name, description, current_price, is_active
(branch_id, product_id) -> quantity_on_hand, reorder_level, last_counted_at
customer_id -> first_name, last_name, email, phone, is_active
address_id -> customer_id, label, address fields, is_default
order_id -> order_number, customer_id, branch_id, delivery_address_id,
            order_channel, fulfilment_method, order_status, order amounts, placed_at
(order_id, product_id) -> quantity, unit_price
payment_id -> order_id, provider, provider_reference, amount, status, method, timestamps
order_id -> fulfilment_status, tracking_reference, fulfilment timestamps
```

The alternate identifiers also determine their respective rows, for example `sku -> product_id, ...`, `order_number -> order_id, ...`, and `provider_reference -> payment_id, ...`.

## Normalisation process

### Unnormalised form

A single sales record could initially resemble:

```text
ORDER(order_number, placed_at,
      customer_name, customer_email, customer_phone,
      customer_address,
      branch_code, branch_name,
      {sku, product_name, quantity, current_price},
      {payment_reference, payment_status})
```

The repeating product and payment groups make this unnormalised. Customer, branch, and product facts would also be copied into every order, creating update and deletion anomalies.

### First normal form (1NF)

Repeating groups are separated so each field contains one value and each row represents one fact. Order products become `order_item` rows and payment attempts become `payment` rows. Customer addresses are stored as individual `customer_address` rows rather than a list inside a customer column.

### Second normal form (2NF)

Relations with composite business keys are checked for partial dependencies. In an early order-line relation keyed by (`order_id`, `product_id`), order date depends only on `order_id`, while product name depends only on `product_id`. Those attributes are moved to `sales_order` and `product`; only quantity and the agreed unit price remain facts about the whole order-product combination.

Likewise, `inventory` is keyed by (`branch_id`, `product_id`). Branch address is stored in `branch` and product description in `product`; only stock facts that depend on both identifiers remain in `inventory`.

### Third normal form (3NF)

Transitive dependencies are removed:

- category name and description depend on `category_id`, not indirectly on a product, so they are stored in `category`;
- branch details depend on `branch_id`, not on an order, so they are stored in `branch`;
- customer contact data depends on `customer_id`, while address details depend on `address_id`, so neither is repeated in `sales_order`;
- fulfilment facts are separated from the order header because they describe a distinct optional lifecycle record.

Every non-key stored attribute therefore depends on the key, the whole key, and nothing but the key. The operational schema is in 3NF.

## Intentional snapshots and derived values

`product.current_price` and `order_item.unit_price` are not duplicate representations of the same fact. The first is today's catalogue price; the second is the immutable price agreed for a particular order line. Keeping the snapshot prevents historical sales values from changing when the catalogue is updated.

`order_item.line_total` and `sales_order.grand_total` are generated columns, not independently editable values. PostgreSQL derives them from their component values, preventing inconsistent arithmetic while making reporting clearer. The order `subtotal` is retained as an order-level financial snapshot and is set from the order items by the transaction workflow in Portfolio 3.

## Integrity choices that need application or transaction logic

SQL constraints enforce row-level and referential rules, but some cross-row rules require controlled transactions:

- a confirmed order must contain at least one item;
- the subtotal must equal the sum of its order-item line totals;
- available inventory must be checked and reduced atomically;
- only valid order-status transitions should be accepted;
- only one default address per customer should be active.

These rules are deliberately identified here rather than incorrectly represented as simple `CHECK` constraints. The relevant transaction and indexing mechanisms are implemented and tested in the corresponding portfolio activities.
