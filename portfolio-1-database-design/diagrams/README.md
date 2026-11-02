# AsterMart Entity Relationship Diagram

GitHub renders the following Mermaid diagram as a visual crow's-foot ERD. The [detailed Mermaid source](astermart-erd.mmd) also lists every modelled attribute and identifies primary, foreign, and unique keys.

```mermaid
erDiagram
    BRANCH ||--o{ INVENTORY : holds
    CATEGORY ||--o{ PRODUCT : classifies
    PRODUCT ||--o{ INVENTORY : stocked_as
    CUSTOMER ||--o{ CUSTOMER_ADDRESS : stores
    CUSTOMER ||--o{ SALES_ORDER : places
    BRANCH ||--o{ SALES_ORDER : fulfils
    CUSTOMER_ADDRESS o|--o{ SALES_ORDER : delivers_to
    SALES_ORDER ||--|{ ORDER_ITEM : contains
    PRODUCT ||--o{ ORDER_ITEM : appears_in
    SALES_ORDER ||--o{ PAYMENT : has
    SALES_ORDER ||--o| FULFILMENT : progresses_through
```

## Cardinality notes

- `inventory` resolves the many-to-many relationship between branches and products.
- `order_item` resolves the many-to-many relationship between orders and products and preserves the price at purchase time.
- An order is assigned to exactly one customer and one fulfilling branch.
- A delivery address is optional from the general order perspective because pickup orders have no delivery address; a database check makes it mandatory specifically for delivery orders.
- An order may have several payment attempts but at most one fulfilment record in the current scope.
