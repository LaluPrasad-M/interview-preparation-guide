# MongoDB Food Delivery Schema

> [!tldr]
> Worked example: schema design for a food delivery platform, including geospatial queries, denormalisation, and traffic spike handling.

Part of [[schema-design]].

---

## Worked example: food delivery collections

The order document is one piece of the design. The rest of the collections follow the same query first logic.

See [[food-delivery-schema]] for the same domain modelled relationally, table by table.

### Restaurants, geo and read heavy

The main queries are: find nearby restaurants, filter by cuisine, sort by rating.

```json
{
  "_id": "rest123",
  "name": "Burger Hub",
  "location": { "type": "Point", "coordinates": [77.61, 12.93] },
  "cuisines": ["Burgers", "Fast Food"],
  "avgRating": 4.3,
  "isOpen": true
}
```

`location` is a GeoJSON `Point`, which is what lets MongoDB run geospatial queries on it directly.

```js
db.restaurants.createIndex({ location: "2dsphere" })
db.restaurants.createIndex({ cuisines: 1, isOpen: 1 })
```

The `2dsphere` index answers "what's near me". The compound index answers "what's open, in this cuisine" without a collection scan.

Restaurant listing tolerates eventual consistency: `avgRating` updates asynchronously, and reads can go to secondaries.

### Menus, embedded items

A menu is its own collection, not embedded in the restaurant, because it is large and updated independently of the restaurant's own fields.

```js
{
  _id: "menu123",
  restaurantId: "rest123",
  items: [
    { itemId: "i1", name: "Burger", price: 199 },
    { itemId: "i2", name: "Fries", price: 99 }
  ],
  updatedAt: ISODate()
}
```

Inside the menu, items are embedded rather than referenced. The list is bounded per restaurant, and a single fetch returns the whole menu.

### Payments, one per order

```js
{
  _id: "pay123",
  orderId: "order123",
  status: "SUCCESS",
  amount: 398,
  method: "UPI",
  createdAt: ISODate()
}
```

Order and payment update together inside a MongoDB transaction with `writeConcern: { w: "majority" }`. A payment succeeding while the order stays unconfirmed is the kind of inconsistency this design cannot afford.

### Reviews, eventual by design

```json
{
  "_id": "rev123",
  "orderId": "order123",
  "restaurantId": "rest123",
  "rating": 5,
  "comment": "Great food"
}
```

A review does not update the restaurant's `avgRating` inline. A background worker recomputes it asynchronously, the same eventual consistency trade off as the restaurant listing above.

---

## Handling traffic spikes

Lunch and dinner produce predictable load spikes rather than random ones, so the mitigations are mostly about the read path, not the write path.

- **Read replicas** for restaurant and menu reads, so browsing does not compete with order writes for the primary.
- **[[cdn|CDN]] cache** for menu images, since they are large, static, and shared across every user looking at that restaurant.
- **Pre-computed nearby restaurants**, refreshed periodically, instead of running the `2dsphere` query on every request.
- **Rate limiting** on order creation, to protect the write path when everyone orders at once.

---

## Idempotent order creation

Order creation needs the idempotency key technique from [[idempotency]]. In this design, the client sends an idempotency key and it is stored on the order document itself, so a retried create request finds the existing order instead of inserting a second one.

---

## The design checklist

Before you say done: queries identified, embed against reference justified, document size safe, indexes defined, sharding discussed, failure cases considered.

> [!tip] The closing one liner
> My MongoDB designs are query driven, embed for performance, reference for scale, and shard for growth.
