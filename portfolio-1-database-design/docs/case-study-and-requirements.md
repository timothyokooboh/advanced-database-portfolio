# AsterMart Case Study and Requirements

## Organisation profile

AsterMart Retail & Fulfilment Ltd. is a simulated Nigerian retailer operating physical branches alongside an online storefront. Its catalogue includes groceries, household products, and personal-care items. Customers place orders for delivery or pickup, while branch staff maintain stock and fulfil orders.

The organisation needs a reliable database because stock is shared by in-store operations and online orders. A confirmed online order must preserve the exact product price charged, maintain an auditable payment history, and identify the branch responsible for fulfilment.

## Database users

| User | Main database interaction |
| --- | --- |
| Customer | Maintain a profile and addresses, browse products, place orders, and view order status |
| Branch staff | Review orders, update fulfilment status, and confirm pickup or dispatch |
| Inventory officer | Maintain branch stock levels and reorder thresholds |
| Finance officer | Reconcile payment attempts, successful payments, and refunds |
| Operations manager | Analyse sales, stock availability, and fulfilment performance |
| Database administrator | Control access, monitor integrity, back up data, and tune performance |

## Major data to be stored

- branches and their operating details;
- customers and reusable delivery addresses;
- product categories, products, and product prices;
- inventory quantity and reorder level for each product at each branch;
- orders and the products, quantities, and prices captured on each order;
- payment attempts and their external provider references;
- delivery or pickup fulfilment details and status history timestamps.

## Key operations

1. Register a customer and maintain delivery addresses.
2. Browse active products by category and check stock at a selected branch.
3. Place a delivery or pickup order containing one or more products.
4. Calculate an order total from immutable order-line prices and quantities.
5. Record multiple payment attempts without duplicating a provider transaction.
6. Deduct branch inventory only when the order workflow permits it.
7. Move an order through controlled fulfilment states.
8. Find low-stock products and calculate sales or fulfilment metrics.

## Business rules

Identifiers use database-generated numeric keys, while stable business identifiers such as SKU, email, branch code, order number, and provider reference are also unique.

1. A product belongs to exactly one category; a category can contain many products.
2. A branch stocks many products and a product can be stocked by many branches. Each branch-product pair has one inventory record.
3. Inventory quantity and reorder level cannot be negative.
4. A customer may store several addresses, but an address belongs to one customer.
5. Every order belongs to one customer and is fulfilled by one branch.
6. An order must contain at least one order item before application logic marks it confirmed.
7. A product can occur only once in an order. Quantity must be positive.
8. The unit price stored on an order item is the price agreed at purchase time; later changes to a product's catalogue price must not rewrite order history.
9. Delivery orders require a customer address. Pickup orders must not use a delivery address.
10. The order subtotal equals the sum of order-item line amounts. Delivery fees and discounts are stored separately to preserve the calculation.
11. An order may have multiple payment attempts, but a payment-provider reference can appear only once.
12. Monetary values cannot be negative, except that discounts are represented as a non-negative amount subtracted from the total.
13. Each order has at most one fulfilment record in this scope.
14. Product rows are deactivated rather than deleted when historical orders refer to them.

## Assumptions

- All monetary values are stored in Nigerian naira using `NUMERIC`, never floating-point types.
- A single order is fulfilled from one branch; cross-branch fulfilment is outside the initial scope.
- Authentication credentials and card details are not stored in the portfolio database.
- Payment processing is external; AsterMart stores provider names, references, statuses, and amounts only.
- Timestamps are stored with time-zone awareness and interpreted in the user's local time at the application boundary.

## Advanced-database opportunities

This scenario supports later portfolio activities without changing the case study:

- composite and partial indexes can be compared with sequential scans for order and inventory reports;
- concurrent purchases of scarce stock can demonstrate lost updates, row locking, and transaction isolation;
- product attributes or order-event data can be modelled as MongoDB documents;
- branch-oriented partitioning, replication, availability, and consistency can be evaluated in a distributed design.
