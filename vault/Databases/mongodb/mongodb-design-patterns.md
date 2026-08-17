# MongoDB Design Patterns

> [!tldr]
> Denormalisation trades consistency for read performance; index strategy, document sizing, and lifecycle complexity shape production schema design.

Part of [[schema-design]].

---

## Denormalisation

Denormalisation in MongoDB is the intentional duplication of data to optimise read performance and preserve atomicity. It is not only copying raw fields, it also includes storing derived or aggregated data.

The key word is intentional. It is not accidental redundancy, it is a design choice.

MongoDB encourages it because MongoDB is optimised for fast reads, single document atomic operations and high scale. Reads usually need complete objects, joins are expensive, and document reads are cheap.

**Denormalisation check.** Can I duplicate small data to avoid `$lookup`? Can I store aggregates such as `avgRating`, `orderCount` or `lastOrderStatus`? Is eventual consistency acceptable?

MongoDB prefers duplication over joins.

---

## Index strategy, mandatory

Every query backed by an index. Compound indexes follow filter, then sort, then projection. Avoid over indexing write heavy collections. Use partial indexes where possible.

```js
{ userId: 1, createdAt: -1 }
```

---

## Document size and growth

Any unbounded arrays? Any frequent `$push`? Any risk of hot documents?

> [!warning] Growing arrays plus sharding is a disaster.

---

## Order lifecycle complexity, a worked case

**Simple lifecycle, low complexity.** `PLACED -> CONFIRMED -> DELIVERED`. Few states, single owner, minimal race conditions. Design: a single orders document with an embedded status field and atomic updates.

**Real food delivery lifecycle, high complexity.**

```text
PLACED
-> PAYMENT_PENDING
-> PAYMENT_SUCCESS
-> RESTAURANT_ACCEPTED
-> PREPARING
-> READY_FOR_PICKUP
-> PICKED_UP
-> ON_THE_WAY
-> DELIVERED
-> COMPLETED / CANCELLED / REFUNDED
```

Who updates what: the user cancels, the payment service owns payment state, the restaurant owns preparation, the delivery partner owns pickup and delivery.

This is hard because of concurrent updates, partial failures, required idempotency, and the need for an audit trail.

| Concern | Design choice |
| --- | --- |
| Multiple updates | a single orders document |
| State history | embedded `statusTimeline[]` |
| Atomicity | transactions or `$set` |
| Debugging | an event log inside the order |

```json
{
  "_id": "order123",
  "status": "ON_THE_WAY",
  "statusTimeline": [
    { "state": "PLACED", "at": "10:01" },
    { "state": "PREPARING", "at": "10:10" },
    { "state": "ON_THE_WAY", "at": "10:35" }
  ]
}
```

> [!tip] Say this
> Order lifecycle is complex and state driven, so I would keep the entire lifecycle in a single order document to ensure atomic updates, strong consistency, and easy state validation.
