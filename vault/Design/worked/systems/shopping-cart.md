# Shopping Cart

> [!tldr]
> A cart is a transactional stateful entity where correctness beats schema flexibility. A version column solves the concurrency, with no Redis locks and no distributed mutex.

---

## The challenges

Concurrent cart changes. Consistency with inventory. Low latency. Atomicity of mutations.

---

## Functional requirements

Each user has one active cart. It supports add item, update quantity, remove item and view. An item is a `product_id` and a `quantity`. The cart stays valid under concurrent requests, and inventory is validated but **not reserved** during cart operations.

---

## Non functional requirements

| NFR | What it means | Why it matters here |
| --- | --- | --- |
| Strong consistency per user | the user always sees their latest cart | prevents lost updates, like a quantity going 2 to 1 unexpectedly |
| Low latency | responses in milliseconds | the cart is user facing, slow means bad UX |
| Atomic updates | each mutation happens fully or not at all | avoids an item added without its quantity |
| Scalability | millions of users | large e-commerce scale |
| Idempotency | retrying does not duplicate | mobile and flaky networks retry |
| High availability | reads almost never fail | users browse far more than they update |

---

## Why a relational database

The cart needs atomic updates, strong consistency per user, concurrent safety with no lost updates, and simple invariants such as no duplicate products and no negative quantity.

A relational database gives all of that for free: transactions, row level locking, constraints and optimistic locking via a version column.

> [!tip] The interview safe line
> A shopping cart is a transactional, stateful entity where correctness matters more than schema flexibility, so a relational database is a natural fit.

That is about fit, not about one database being bad.

---

## Modelling it from scratch

**Step 1, the nouns.** User, cart, cart item, and product or inventory as an external concern. We focus on cart and cart item.

**Step 2, table boundaries.** This is the SQL version of the embed against reference question.

The bad option is a single table holding an items array. Updating one item rewrites the whole row, uniqueness per product is hard to enforce, concurrency is messy, and there is no partial row locking.

The correct option splits `carts` for cart level state and `cart_items` for product level state.

### The carts table

```text
carts
--------------------------------
cart_id      (PRIMARY KEY)
user_id      (UNIQUE)
status       (active, checked_out)
version      (INT)
created_at
updated_at
```

**Why each column.** `cart_id` is a surrogate key, which makes joins easier and gives a stable identifier. Primary keys do not need business meaning.

`user_id UNIQUE` enforces one active cart per user, at the database rather than in application code. That is a strong interview signal.

`version` enables optimistic locking and prevents lost updates. Without it concurrency gets complicated fast.

### The cart_items table

```text
cart_items
--------------------------------
cart_item_id  (PRIMARY KEY)
cart_id       (FOREIGN KEY -> carts)
product_id
quantity
UNIQUE (cart_id, product_id)
```

`UNIQUE (cart_id, product_id)` enforces that one product appears only once per cart. In a document store you enforce that in code, here the database guarantees it.

You could use `(cart_id, product_id)` as the primary key, but interviewers prefer clarity over cleverness.

The foreign key means a cart item cannot exist without a cart.

> [!tip] The phrasing
> Foreign keys encode domain rules directly into the schema.

### The inventory table

```text
inventory
--------------------------------
product_id (PK)
available_quantity
```

Inventory is not modified during cart operations. Reserving happens at checkout. See [[flash-sale-inventory]] for when reservation does happen.

---

## Mapping document concepts to SQL

| Document concept | SQL equivalent |
| --- | --- |
| Document | row |
| Collection | table |
| Embedded document | same table |
| Referenced document | foreign key |
| Schema validation | constraints |
| App level checks | DB level guarantees |

So where you would ask "embed or reference", here you ask "one table or multiple tables with a foreign key". See [[schema-design]].

---

## Why this handles concurrency naturally

Request A adds product X while request B removes it. Both touch the same `cart_id` and both update `version`. Only one succeeds, and the other retries.

Nothing fancy: no Redis locks, no distributed mutex, just a version column.

| Mechanism | What it does |
| --- | --- |
| SQL atomicity | ensures partial updates do not happen |
| Row level lock | prevents simultaneous physical writes |
| Version check | prevents lost updates |
| Application retry | resolves conflicts cleanly |

> [!tip] Interview gold
> Relational databases already solve most of the concurrency problems we care about here.

A document store could do this, but with multi document transactions, manual uniqueness guarantees and more application logic. See [[locking-strategies]].

---

## The architecture

```text
Client (Web / Mobile)
        |
        v
   Cart Service
        |
        v
 Relational Database
        |
        v
 Inventory Service (read only during cart ops)
```

No queues and no async here. The cart is synchronous and stateful.

---

## The API

```text
GET /cart
```

```json
{
  "cartId": "c1",
  "items": [
    { "productId": "p1", "quantity": 2 },
    { "productId": "p2", "quantity": 1 }
  ],
  "version": 5
}
```

```text
POST /cart/items
```

```json
{
  "productId": "p1",
  "quantity": 2,
  "version": 5
}
```

The client sends back the `version` it read, which is what makes the write idempotent and detects a concurrent modification. See [[idempotency]].

---

## Checkout consistency

Everything before checkout is optimistic and cheap: add, update, and remove only touch the cart tables. Checkout is the one place that needs a real transaction.

```text
BEGIN TRANSACTION
  Lock inventory rows
  Validate quantities
  Decrement inventory
  Mark cart as checked_out
COMMIT
```

Locking the inventory rows first means a second checkout for the same product waits instead of reading a stale `available_quantity`. If validation fails, the whole transaction rolls back and the cart stays active.

---

## Caching the cart

Reads happen far more often than writes, so the cart sits behind a cache.

| Setting | Value |
| --- | --- |
| Key | `cart:{userId}` |
| TTL | 30 to 60 seconds |
| Read | cache aside |
| Write | invalidate |

The database stays the source of truth. The cache only shortens the common read path, it is never consulted for correctness.

---

## What can go wrong in production

| Problem | Fix |
| --- | --- |
| Lost updates | optimistic locking |
| Duplicate items | a database unique constraint |
| Overselling | validate at checkout |
| Stale cache | write through invalidation |
| High retries | backoff plus a retry limit |

---

## Observability

**Metrics.** Cart update conflicts, and inventory validation failures at checkout.

**Logs.** `cart_id` as the correlation id, so one cart's whole history is a single grep away.

**Alerts.** A spike in update conflicts, and any checkout that reports an inventory mismatch.
