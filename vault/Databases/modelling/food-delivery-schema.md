# Worked Schema: Food Delivery

> [!tldr]
> The ten design questions applied end to end. Every table exists for a stated reason, and the interesting one is why `order_items` duplicates data that already lives in `menu_items`.

Walk [[schema-design-questions]] alongside this. Each table below names the question that produced it.

The same domain modelled as documents, restaurants, menus, payments and reviews, lives in [[schema-design]].

---

## The eight tables

Users, restaurants, menu items, orders, order items, payments, drivers, deliveries. Now justify each one, which is the important part.

---

## users

Users sign up, log in, manage a profile, save addresses and place orders. They can exist without ever placing an order, so they clearly have an independent lifecycle.

```sql
users (
   id BIGINT PRIMARY KEY,
   name VARCHAR(255),
   email VARCHAR(255) UNIQUE,
   phone VARCHAR(20),
   created_at TIMESTAMP
)
```

**Why `UNIQUE(email)`?** It is a business level uniqueness requirement, enforced by the database rather than by code.

**Why `BIGINT`?** These systems scale heavily, so avoid exhausting a smaller integer type.

---

## restaurants

Restaurants onboard independently, manage timings, receive orders and update menus. Independent lifecycle again.

```sql
restaurants (
   id BIGINT PRIMARY KEY,
   name VARCHAR(255),
   address TEXT,
   cuisine_type VARCHAR(100),
   rating DECIMAL(2,1),
   created_at TIMESTAMP
)
```

`DECIMAL` rather than a float, to avoid precision problems.

**Why store `rating` at all?** Initially it might be computed dynamically. Later it is likely denormalised, because the restaurant page is heavily read and computing an average on every request is expensive.

That comes from question 1, entities, and question 6, query patterns. A read heavy access pattern influences denormalisation.

---

## menu_items

Can a restaurant have many menu items? Obviously. Can they change independently, in price, availability and description? Yes.

Independent lifecycle plus a one to many relationship gives its own table.

```sql
menu_items (
   id BIGINT PRIMARY KEY,
   restaurant_id BIGINT,
   name VARCHAR(255),
   description TEXT,
   price DECIMAL(10,2),
   is_available BOOLEAN,
   created_at TIMESTAMP
)
```

The foreign key is `restaurant_id REFERENCES restaurants(id)`.

This also answers question 3, what data grows dynamically. A restaurant can have 5 items or 500, which is a variable length structure, so it becomes a separate table.

---

## orders

The heart of the system. Orders have status transitions, payment linkage, delivery linkage, timestamps, cancellation and refunds. They are critical business entities, not activity records.

```sql
orders (
   id BIGINT PRIMARY KEY,
   user_id BIGINT,
   restaurant_id BIGINT,
   total_amount DECIMAL(10,2),
   status VARCHAR(50),
   created_at TIMESTAMP
)
```

Users to orders is one to many. This comes from question 1, independent lifecycle, and question 7, consistency sensitive workflows, because orders must stay consistent around payment, inventory and refunds.

---

## order_items, the important one

Can one order contain many items? Yes. Can one menu item appear in many orders? Yes. That is a many to many relationship between orders and menu items, which means a join table.

> [!tip] The modelling idea
> The database does not store `orders <-> menu_items` directly. It becomes `orders -> order_items <- menu_items`.

```sql
order_items (
   id BIGINT PRIMARY KEY,
   order_id BIGINT,
   menu_item_id BIGINT,
   quantity INT,
   item_name VARCHAR(255),
   item_price DECIMAL(10,2)
)
```

### Why duplicate `item_name` and `item_price`?

`menu_items` already has both. So why store them again?

Suppose a burger's price changes from 200 to 300. Should old orders now show 300? Obviously not. Old orders must preserve historical truth.

That is question 5, historical snapshotting, and the answer is intentional denormalisation.

> [!tip] The strong answer
> Orders are immutable transactional records, while restaurant profiles are mutable master data. So production systems snapshot critical display and business fields such as name, address, pricing and tax info into the order itself, to preserve historical accuracy, auditability, and resilience against future entity changes or deletions.

See [[invariants]] for the historical consistency invariant this enforces.

---

## payments

Can payments fail independently, retry independently, refund independently? Absolutely. So they deserve their own lifecycle.

```sql
payments (
   id BIGINT PRIMARY KEY,
   order_id BIGINT,
   amount DECIMAL(10,2),
   payment_method VARCHAR(50),
   status VARCHAR(50),
   transaction_reference VARCHAR(255),
   created_at TIMESTAMP
)
```

One order may have multiple payment attempts. That alone justifies a separate table. See [[payment-ingestion]].

---

## drivers

Drivers onboard independently, go online and offline, and accept deliveries. Independent lifecycle.

```sql
drivers (
   id BIGINT PRIMARY KEY,
   name VARCHAR(255),
   phone VARCHAR(20),
   vehicle_number VARCHAR(50),
   created_at TIMESTAMP
)
```

---

## deliveries

Should `driver_id` just live inside `orders`? Weak designs often do that initially.

Stronger reasoning: the delivery itself has a lifecycle. It is assigned, picked up, delivered, sometimes reassigned. So it deserves its own entity.

```sql
deliveries (
   id BIGINT PRIMARY KEY,
   order_id BIGINT,
   driver_id BIGINT,
   assigned_at TIMESTAMP,
   delivered_at TIMESTAMP,
   status VARCHAR(50)
)
```

This comes from question 1, independent lifecycle, and question 4, update frequency, because delivery state changes frequently.

---

## Then: what changes frequently

Driver location. Would you permanently store latitude and longitude inside the `drivers` table?

Initially, maybe. At scale, high frequency writes become the problem, so `driver_locations` eventually separates out. That is the general rule from question 4: a different update frequency may justify separation. See [[proximity-discovery]] for where those coordinates actually go.

---

## Then: what is queried together

The restaurant page fetches the restaurant, its menu and its rating together. So rating and review count may later denormalise onto the restaurant row, which is where the `rating` column above came from.
