db = db.getSiblingDB("astermart_catalog");

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

assert(db.products.countDocuments() === 500, "Expected 500 product documents");
assert(db.order_events.countDocuments() === 5000, "Expected 5,000 order events");
assert(db.products.distinct("category.name").length === 10, "Expected 10 categories");
assert(
  db.products.countDocuments({ "category.name": "Electronics", "attributes.warrantyMonths": { $exists: true } }) === 50,
  "All electronics should have warranty attributes"
);
assert(
  db.products.countDocuments({ "category.name": "Beverages", "attributes.volumeMl": { $exists: true } }) === 50,
  "All beverages should have volume attributes"
);
assert(
  db.order_events.countDocuments({ orderNumber: "ORD-20260101-000001" }) === 5,
  "The sample order should have a five-event timeline"
);
assert(db.products.getIndexes().length === 6, "Expected _id plus five product indexes");
assert(db.order_events.getIndexes().length === 4, "Expected _id plus three event indexes");

let validationRejected = false;
try {
  db.products.insertOne({
    productId: Long(999999),
    sku: "INVALID",
    name: "Invalid test product",
    category: { categoryId: Long(1), name: "Groceries" },
    price: NumberDecimal("-1.00"),
    attributes: {},
    availability: [],
    updatedAt: new Date()
  });
} catch (error) {
  validationRejected = true;
}
assert(validationRejected, "Schema validation should reject an invalid product");

printjson({
  result: "PASS",
  checks: "counts, flexible attributes, event timeline, indexes, and schema validation",
  products: db.products.countDocuments(),
  orderEvents: db.order_events.countDocuments()
});
