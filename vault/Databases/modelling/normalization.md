# Normalisation

> [!tldr]
> Store each fact only once. That is the whole idea, and everything else follows from it.

---

## What normalisation is

A database design technique used mainly in relational databases to organise data so as to reduce duplication and avoid inconsistency.

In short: store each fact only once, split data into multiple related tables, and use joins to combine data.

---

## Why it exists

Without normalisation, the same data sits in many places. Updating it becomes risky, and bugs and inconsistencies creep in.

Normalisation solves update anomalies, insert anomalies and delete anomalies.

---

## The example

### Unnormalised

| OrderId | UserName | UserPhone | Restaurant | Item | Price |
| --- | --- | --- | --- | --- | --- |
| 1 | Rahul | 9999 | Burger House | Burger | 199 |
| 2 | Rahul | 9999 | Burger House | Fries | 99 |

User info is repeated, the restaurant is repeated, and if the phone changes you have to update it everywhere.

### Normalised

**Users.** `userId`, `name`, `phone`

**Restaurants.** `restaurantId`, `name`

**Orders.** `orderId`, `userId`, `restaurantId`

**OrderItems.** `orderId`, `item`, `price`

Now each fact is stored once, relationships are held via IDs, and joins reconstruct the data.

---

## Why MongoDB is called non relational

Because it has no foreign keys, no enforced referential integrity, no standard normalisation, and no optimised join layer. Relationships exist logically, not structurally.

So when documentation says the data is not relational, it means the data does not need normalisation, does not need referential integrity, and does not require join heavy queries.

Mongo works best when you model as documents, not as normalised tables. See [[schema-design]].

---

## Serialisation, since it comes up here

Serialisation converts an in memory object to a byte format for network transfer, disk storage or caching. Deserialisation converts it back.

Common formats: JSON, BSON, XML, YAML, Protocol Buffers, Avro, MessagePack.

```js
// serialisation
const obj = { name: "Rahul", age: 26 };
const jsonString = JSON.stringify(obj);

// deserialisation
const parsedObj = JSON.parse(jsonString);
```

In the database context, MongoDB stores data on disk as BSON, binary JSON. Clients read and write using JSON. The driver converts to and from BSON automatically. You do not need to manually stringify unless you are working with Redis, Kafka, a network API and so on.

Document stores are good when you do not need complex joins, you mostly store and fetch documents, and entire object graphs fit as a single document. Typical cases are logs, events, user profiles, shopping carts and analytics payloads.

---

## The normal forms, practically

You do not need textbook definitions, but you need the practical rule behind each one.

| Form | Textbook rule | What it actually means |
| --- | --- | --- |
| 1NF | atomic values | do not store repeating or array like data badly |
| 2NF | no partial dependency | data should belong fully to the entity or key |
| 3NF | no transitive dependency | the table should describe one thing cleanly |

### 1NF in practice

Every column holds a single value.

```text
Bad:  tags = "node, sql, backend"
Good: a separate user_tags table
```

```text
Bad:                              Good:
| order_id | item1 | item2 |      order_items
                                  | order_id | item |
```

Same for a `phone_numbers` column holding `999,888`, which becomes a `user_phones` table.

### 2NF in practice

This only applies to tables with a composite primary key. Every column must depend on the whole key, not part of it.

```text
order_items
| order_id | menu_item_id | menu_item_name |

Primary key: (order_id, menu_item_id)
```

Does `menu_item_name` depend on the full key, or only on `menu_item_id`? Only the latter. That is a partial dependency, and it creates duplication.

The fix is moving `menu_item_name` to the `menu_items` table, leaving `order_items` with only relationship specific data: `order_id`, `menu_item_id`, `quantity`.

> [!question] Why not just make `order_id` the primary key?
> A primary key must be unique, and `order_id` repeats across different `menu_item_id` values in the same order. Hence the composite.

> [!tip] The interview friendly phrasing
> In relationship tables, I avoid storing data that belongs entirely to another entity.

### 3NF in practice

Non key columns should depend only on the primary key, not on each other.

```text
Bad: a table with zip_code, city, state
```

City and state depend on the zip code, not on the row's own key. That is a transitive dependency, and the fix is moving them to a `locations` table referenced by `zip_code`.

Another example: `user_id -> city -> pincode`, where `pincode` depends on `city` rather than directly on the user.

---

## When to denormalise

Normalisation suits write heavy systems, because it keeps data consistent. Denormalisation suits read heavy systems, because it makes reads fast.

**The problem.** At scale, joins become slow and expensive.

**The solution.** Intentionally duplicate data to avoid the join. Instead of running `SELECT COUNT(*) FROM comments WHERE post_id = 123` on every page load, add a `comment_count` column to the posts table.

**The trade off.** You gain read performance, but now you maintain consistency yourself. Every comment added or deleted must update the count, usually via an async job, a trigger or the same transaction.

---

## Foreign keys, or not

A classic senior debate.

**For foreign keys.** The database guarantees referential integrity, so orphan records are impossible.

**Against them, at high scale.** Constraints make the database check the parent table on every insert and update, which slows high throughput writes. And once you shard across servers, foreign keys physically cannot work across databases. The alternative is enforcing referential integrity in application code.

---

## The soft delete gotcha

Instead of a physical `DELETE`, add `deleted_at TIMESTAMP` defaulting to `NULL`, and every `SELECT` adds `WHERE deleted_at IS NULL`.

> [!warning] Soft delete breaks unique constraints
> With `UNIQUE(email)`, user A deletes their account, `deleted_at` is set, and the row remains. User B signs up with the same email and the database throws a duplicate error.
>
> The fix is a composite constraint, `UNIQUE(email, deleted_at)`. Postgres handles it more elegantly with a partial index:
>
> ```sql
> CREATE UNIQUE INDEX ON users (email) WHERE deleted_at IS NULL;
> ```

---

## Junction tables carry payload

Any many to many relationship, users to roles, students to courses, products to categories, needs a junction table.

> [!tip] The insight
> Junction tables are not just pairs of IDs. They are the natural home for contextual data about the relationship itself.

In `user_roles`, add `granted_by` for who assigned the role and `created_at` for when. That data belongs to the relationship, not to either entity.

---

## Audit log design

A frequent question: how do we track the history of changes to a payment record?

**Level 1, application level.** Your code writes to a `payment_audit_logs` table on every update. The flaw is that a bug, or any other writer, bypasses the log.

**Level 2, database triggers.** The database saves the old row state to an audit table on `UPDATE` or `DELETE`. The flaw is that triggers are hidden logic and hard to debug.

**Level 3, change data capture.** A tool like Debezium reads the write ahead log and streams every change as an event. The application does not know it is happening, and there is no performance impact on the main database. See [[change-data-capture]].
