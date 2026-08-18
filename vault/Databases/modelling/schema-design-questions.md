# The Ten Database Design Questions

> [!tldr]
> When someone says "design the schema for X", walk these ten in order. They are engineering reasoning steps, not academic rules.

---

## The list

1. What are the entities? What exists independently in the business domain?
2. What are the relationships? How are they connected, one to one, one to many, many to many?
3. What data repeats or grows dynamically? Any variable length or multi valued data?
4. What changes frequently? Which fields are volatile, and what is the workload shape?
5. What needs historical snapshotting? What must preserve truth even when the source changes?
6. What is read constantly but expensive to compute?
7. What requires strong consistency? Which workflows cannot become inconsistent?
8. Normalise or denormalise? What is the consistency against performance trade off?
9. What is the deletion strategy? Hard delete, soft delete, retention, compliance, auditability?
10. What will scale fastest? Which tables grow or take writes far faster than the rest?

---

## 1. The entities

Ask what exists independently in the business domain. Entities usually become tables. In food delivery: users, restaurants, orders, payments, drivers.

**What independent means.** It has its own lifecycle, its own updates, its own business meaning and its own identity. A user can sign up, log in, update their profile and exist without any orders, so `users` deserves its own table.

> [!tip] Golden rule
> An independent lifecycle probably means a separate table.

> [!warning] The common mistake
> Beginners create tables based on UI screens. Strong engineers create them based on business entities, ownership and lifecycle. That difference is enormous.

---

## 2. The relationships

Relationships define foreign keys, join tables and [[cardinality]].

**One to one**, for example user and profile, which is comparatively rare. **One to many**, for example user to orders, which is the most common. **Many to many**, for example orders and menu items, which needs a join table.

> [!tip] Golden rule
> Many to many almost always needs a join table, for example `order_items`.

> [!warning] The common mistake
> Storing repeating columns like `item1, item2, item3` breaks scalability immediately.

---

## 3. Can the values grow dynamically?

Order items, phone numbers, addresses, tags, attachments. An order has N items, a user has N phone numbers, a post has N tags.

```text
Bad:                Good:
orders              order_items
-------             ------------
id                  order_id
item1               item_id
item2
item3
```

> [!tip] Golden rule
> Repeating or variable length data means separate rows in a separate table.

This is 1NF in practice, and the practical understanding matters more than the textbook definition. See [[normalization]].

---

## 4. What changes frequently

Ask which fields get updated constantly, and whether this data has a significantly different write pattern, update frequency, access pattern, lifecycle or scaling characteristic from the rest of the entity.

Examples: driver location, online status, `last_seen`, inventory count.

**Why it matters.** Frequent updates create contention, locking, row bloat and [[write-amplification|write amplification]].

Say `users` holds name, email and `current_location`. If location updates every few seconds, the `users` table becomes hot. Eventually `user_locations` separates out.

> [!tip] Golden rule
> A different update frequency may justify separation.

> [!warning] The common mistake
> People often keep static profile data and highly volatile live data in the same table forever.

---

## 5. Historical snapshotting

Ask whether old records should preserve historical truth. Old prices, old addresses, old tax rates, old names.

If an item price goes from 200 to 300, an old order must still show 200. So inside `order_items` you store `item_name` and `item_price`, even though the menu table already has them.

> [!tip] Golden rule
> Historical transactional data is often intentionally denormalised.

> [!warning] The common mistake
> Over normalising historical data and accidentally mutating history. See [[invariants]].

---

## 6. Read constantly, expensive to compute

Ask what data is usually fetched together. A restaurant page always shows the restaurant, its average rating and its review count. Computing `AVG(review.rating)` on every request gets expensive, so `restaurants.avg_rating` may be stored directly.

> [!tip] Golden rule
> Read heavy access patterns may justify denormalisation.

> [!warning] The common mistake
> Designing purely for normalisation without considering read patterns.

---

## 7 and 8. Consistency, and where invariants live

Ask what absolutely cannot become inconsistent: payments, wallet balance, inventory. Those need transactions and constraints at the database layer.

Then decide normalise or denormalise, which is the consistency against performance trade off. See [[invariants]] for which invariant belongs in the database and which belongs in the service layer.

---

## 9. The deletion strategy

Hard delete, soft delete, retention windows, compliance and auditability. See [[zero-downtime-migration]] for archiving and partition dropping.

---

## 10. What scales fastest

Which tables grow or take writes far faster than the rest. That table is the one that will need partitioning, sharding or a separate store first, and knowing it early shapes everything above.
