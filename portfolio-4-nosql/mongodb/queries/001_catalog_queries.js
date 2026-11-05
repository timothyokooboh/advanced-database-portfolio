db = db.getSiblingDB("astermart_catalog");

print("Q1: Electronics with at least a 12-month warranty");
db.products.find(
  {
    "category.name": "Electronics",
    "attributes.warrantyMonths": { $gte: 12 }
  },
  { _id: 0, sku: 1, name: 1, price: 1, attributes: 1 }
).sort({ price: 1 }).limit(5).forEach(printjson);

print("Q2: Products with 30 units or fewer at branch 3");
db.products.aggregate([
  { $match: { availability: { $elemMatch: { branchId: Long(3), quantity: { $lte: 30 } } } } },
  {
    $project: {
      _id: 0,
      sku: 1,
      name: 1,
      branchAvailability: {
        $filter: {
          input: "$availability",
          as: "stock",
          cond: { $eq: ["$$stock.branchId", Long(3)] }
        }
      }
    }
  },
  { $sort: { "branchAvailability.quantity": 1, sku: 1 } },
  { $limit: 5 }
]).forEach(printjson);

print("Q3: Category catalogue summary");
db.products.aggregate([
  {
    $group: {
      _id: "$category.name",
      productCount: { $sum: 1 },
      minimumPrice: { $min: "$price" },
      maximumPrice: { $max: "$price" },
      averagePrice: { $avg: "$price" }
    }
  },
  { $sort: { _id: 1 } }
]).forEach(printjson);

print("Q4: Complete timeline for one order");
db.order_events.find(
  { orderNumber: "ORD-20260101-000001" },
  { _id: 0, eventId: 1, eventType: 1, occurredAt: 1, actor: 1, payload: 1 }
).sort({ occurredAt: 1 }).forEach(printjson);

print("Q5: Explain category/price access path");
printjson(
  db.products.find(
    { "category.name": "Electronics", price: { $lte: NumberDecimal("25000.00") } },
    { _id: 0, sku: 1, name: 1, price: 1 }
  ).sort({ price: 1 }).explain("executionStats")
);
