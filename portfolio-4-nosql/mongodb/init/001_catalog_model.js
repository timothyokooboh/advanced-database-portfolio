// AsterMart MongoDB document model and deterministic fictional dataset.

db = db.getSiblingDB("astermart_catalog");

db.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["productId", "sku", "name", "category", "price", "attributes", "availability", "updatedAt"],
      properties: {
        productId: { bsonType: "long" },
        sku: { bsonType: "string", pattern: "^AST-PRD-[0-9]{5}$" },
        name: { bsonType: "string", minLength: 1 },
        description: { bsonType: "string" },
        category: {
          bsonType: "object",
          required: ["categoryId", "name"],
          properties: {
            categoryId: { bsonType: "long" },
            name: { bsonType: "string" }
          }
        },
        price: { bsonType: "decimal", minimum: NumberDecimal("0.01") },
        attributes: { bsonType: "object" },
        tags: { bsonType: "array", items: { bsonType: "string" } },
        availability: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["branchId", "branchCode", "quantity", "reorderLevel"],
            properties: {
              branchId: { bsonType: "long" },
              branchCode: { bsonType: "string" },
              quantity: { bsonType: "int", minimum: 0 },
              reorderLevel: { bsonType: "int", minimum: 0 }
            }
          }
        },
        updatedAt: { bsonType: "date" }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

db.createCollection("order_events", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["eventId", "orderNumber", "eventType", "occurredAt", "actor", "payload"],
      properties: {
        eventId: { bsonType: "string" },
        orderNumber: { bsonType: "string", pattern: "^ORD-[0-9]{8}-[0-9]{6}$" },
        eventType: {
          enum: ["ORDER_PLACED", "PAYMENT_CONFIRMED", "PICKING_STARTED", "READY", "DISPATCHED", "COMPLETED"]
        },
        occurredAt: { bsonType: "date" },
        actor: {
          bsonType: "object",
          required: ["type", "id"],
          properties: {
            type: { enum: ["customer", "staff", "system", "courier"] },
            id: { bsonType: "string" }
          }
        },
        payload: { bsonType: "object" }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

const categoryNames = [
  "Groceries", "Beverages", "Fresh Food", "Household", "Personal Care",
  "Baby Care", "Health", "Electronics", "Stationery", "Pet Care"
];
const productPrefixes = [
  "Grocery Item ", "Beverage Item ", "Fresh Food Item ", "Household Item ",
  "Personal Care Item ", "Baby Care Item ", "Health Item ",
  "Electronics Item ", "Stationery Item ", "Pet Care Item "
];
const branchCodes = [
  "AST-LAG01", "AST-LAG02", "AST-ABJ01", "AST-KAN01",
  "AST-PHC01", "AST-IBD01", "AST-ENU01", "AST-BEN01"
];

const products = [];
for (let productId = 1; productId <= 500; productId += 1) {
  const categoryId = ((productId - 1) % 10) + 1;
  let attributes;
  if (categoryId === 2) {
    attributes = { volumeMl: 330 + ((productId % 4) * 170), package: "bottle", sugarFree: productId % 3 === 0 };
  } else if (categoryId === 3) {
    attributes = { weightGrams: 250 + ((productId % 5) * 250), storage: "refrigerated", organic: productId % 4 === 0 };
  } else if (categoryId === 8) {
    attributes = { colour: productId % 2 === 0 ? "black" : "silver", warrantyMonths: 6 + ((productId % 3) * 6), powerWatts: 20 + (productId % 5) * 10 };
  } else if (categoryId === 9) {
    attributes = { colour: productId % 2 === 0 ? "blue" : "black", packSize: 1 + (productId % 10), material: "mixed" };
  } else {
    attributes = { brand: `Aster Select ${categoryId}`, packSize: 1 + (productId % 6), countryOfOrigin: "Nigeria" };
  }

  const availability = [];
  for (let branchId = 1; branchId <= 8; branchId += 1) {
    availability.push({
      branchId: Long(branchId),
      branchCode: branchCodes[branchId - 1],
      quantity: Int32((branchId * 17 + productId * 13) % 240),
      reorderLevel: Int32(20 + ((branchId + productId) % 30))
    });
  }

  products.push({
    productId: Long(productId),
    sku: `AST-PRD-${String(productId).padStart(5, "0")}`,
    name: productPrefixes[categoryId - 1] + String(productId).padStart(3, "0"),
    description: `Fictional AsterMart catalogue product ${productId}`,
    category: { categoryId: Long(categoryId), name: categoryNames[categoryId - 1] },
    price: NumberDecimal(String(500 + ((productId * 137) % 49500)) + ".00"),
    attributes,
    tags: [categoryNames[categoryId - 1].toLowerCase().replaceAll(" ", "-"), productId % 2 === 0 ? "featured" : "standard"],
    availability,
    updatedAt: ISODate("2026-11-05T09:00:00Z")
  });
}
db.products.insertMany(products);

const eventTypes = ["ORDER_PLACED", "PAYMENT_CONFIRMED", "PICKING_STARTED", "DISPATCHED", "COMPLETED"];
const actorTypes = ["customer", "system", "staff", "courier", "customer"];
const events = [];
for (let eventNumber = 1; eventNumber <= 5000; eventNumber += 1) {
  const orderSequence = Math.floor((eventNumber - 1) / eventTypes.length) + 1;
  const eventPosition = (eventNumber - 1) % eventTypes.length;
  const orderDate = new Date(Date.UTC(2026, 0, 1 + ((orderSequence - 1) % 300), 8, 0, 0));
  const occurredAt = new Date(orderDate.getTime() + eventPosition * 60 * 60 * 1000);
  const eventType = eventTypes[eventPosition];
  let payload;
  if (eventType === "ORDER_PLACED") {
    payload = { channel: "online", itemCount: Int32(3), branchId: Long(((orderSequence - 1) % 8) + 1) };
  } else if (eventType === "PAYMENT_CONFIRMED") {
    payload = { provider: "Demo Provider", method: orderSequence % 2 === 0 ? "card" : "transfer" };
  } else if (eventType === "DISPATCHED") {
    payload = { trackingReference: `TRK-DEMO-${String(orderSequence).padStart(8, "0")}`, courier: "Aster Delivery" };
  } else if (eventType === "COMPLETED") {
    payload = { receivedBy: "customer", proofRecorded: true };
  } else {
    payload = { branchId: Long(((orderSequence - 1) % 8) + 1), note: eventType.toLowerCase().replaceAll("_", " ") };
  }

  events.push({
    eventId: `EVT-${String(eventNumber).padStart(8, "0")}`,
    orderNumber: `ORD-20260101-${String(orderSequence).padStart(6, "0")}`,
    eventType,
    occurredAt,
    actor: { type: actorTypes[eventPosition], id: `${actorTypes[eventPosition]}-${orderSequence}` },
    payload
  });
}
db.order_events.insertMany(events);

db.products.createIndex({ sku: 1 }, { unique: true, name: "uq_product_sku" });
db.products.createIndex({ "category.name": 1, price: 1 }, { name: "idx_category_price" });
db.products.createIndex({ tags: 1 }, { name: "idx_product_tags" });
db.products.createIndex({ "availability.branchId": 1 }, { name: "idx_availability_branch" });
db.products.createIndex(
  { name: "text", description: "text", tags: "text" },
  { name: "idx_product_search", weights: { name: 10, tags: 5, description: 1 } }
);
db.order_events.createIndex({ eventId: 1 }, { unique: true, name: "uq_event_id" });
db.order_events.createIndex({ orderNumber: 1, occurredAt: 1 }, { name: "idx_order_timeline" });
db.order_events.createIndex({ eventType: 1, occurredAt: -1 }, { name: "idx_event_type_time" });

printjson({
  initialized: true,
  database: db.getName(),
  products: db.products.countDocuments(),
  orderEvents: db.order_events.countDocuments()
});
