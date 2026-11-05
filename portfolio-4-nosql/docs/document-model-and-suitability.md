# MongoDB Document Model and Suitability

## Why a document model fits selected AsterMart data

AsterMart products share core fields such as SKU, name, category, price, and availability, but their descriptive attributes vary by category. A beverage has volume and sugar-free information; fresh food has weight and storage requirements; electronics has power and warranty details. In a fixed relational table, these differences would produce many nullable columns, repeated subtype joins, or an entity-attribute-value model that is difficult to validate and query.

MongoDB keeps stable fields at the document root and stores category-specific fields in `attributes`. Each product remains one coherent catalogue object. JSON Schema validation still enforces core types and required fields while allowing the attribute object to evolve.

Order lifecycle events also have a stable envelope and variable payload. `PAYMENT_CONFIRMED` records a provider and method, while `DISPATCHED` records a tracking reference and courier. The `order_events` collection preserves these differences without forcing unrelated columns into every event row.

## Product document structure

```javascript
{
  productId: Long(78),
  sku: "AST-PRD-00078",
  name: "Electronics Item 078",
  category: { categoryId: Long(8), name: "Electronics" },
  price: NumberDecimal("11186.00"),
  attributes: { colour: "black", warrantyMonths: 6, powerWatts: 50 },
  tags: ["electronics", "featured"],
  availability: [
    { branchId: Long(1), branchCode: "AST-LAG01", quantity: 71, reorderLevel: 39 }
  ],
  updatedAt: ISODate("2026-11-05T09:00:00Z")
}
```

Category is embedded because its name is read whenever a product is displayed and changes rarely. Branch availability is embedded to serve the common "show this product near me" catalogue read in one document. This is deliberate denormalization.

## Event document structure

```javascript
{
  eventId: "EVT-00000004",
  orderNumber: "ORD-20260101-000001",
  eventType: "DISPATCHED",
  occurredAt: ISODate("2026-01-01T11:00:00Z"),
  actor: { type: "courier", id: "courier-1" },
  payload: {
    trackingReference: "TRK-DEMO-00000001",
    courier: "Aster Delivery"
  }
}
```

Events are separate documents rather than an ever-growing array embedded in an order. This avoids the MongoDB document-size limit and concurrent updates to one hot order document, while the compound `(orderNumber, occurredAt)` index retrieves a complete ordered timeline efficiently.

## Index strategy

- unique `sku` and `eventId` indexes preserve external identity;
- `(category.name, price)` supports category browsing and price ordering/ranges;
- the multikey `tags` index supports tag filters;
- the multikey `availability.branchId` index narrows branch-availability searches;
- the weighted text index supports catalogue search;
- `(orderNumber, occurredAt)` supports chronological timelines;
- `(eventType, occurredAt DESC)` supports operational event monitoring.

Indexes add storage and write amplification, so they are tied to demonstrated query patterns rather than indexing every attribute. Highly variable category attributes should be indexed only when usage evidence justifies a dedicated or wildcard index.

## Consistency boundary

PostgreSQL is the system of record for exact stock, order totals, payments, and transactional deductions. Embedded MongoDB availability is a catalogue projection and may be briefly stale. A production system would update it through change-data capture or an outbox/event consumer and expose the projection timestamp. Checkout must always revalidate and lock PostgreSQL inventory.

MongoDB event documents can be appended after PostgreSQL commits by consuming an outbox. Idempotent `eventId` values and a unique index make retries safe. This avoids an unsafe distributed transaction spanning both databases.

## Advantages and limitations

The model offers flexible attributes, natural object retrieval, embedded read locality, and expressive aggregation. Its costs are duplicated category/availability values, more complex synchronization, and weaker cross-document relational enforcement. MongoDB is therefore used only where its access patterns provide a clear benefit; it does not replace the normalized relational core.
