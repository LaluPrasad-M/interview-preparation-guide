# Multi Region Active Active Cart

> [!tldr]
> The speed of light makes a transatlantic round trip 150 ms. You beat it by putting a full copy of the app in both regions, then merging conflicts mathematically.

---

## The problem

A global platform with active datacenters in Virginia and Ireland.

**The latency problem.** A round trip across the Atlantic takes roughly 150 ms. If our database lives in the US, a European user clicking add to cart suffers 150 ms of lag on every interaction. That is unacceptable for e-commerce.

**How we beat it.** Physically deploy a full copy of the application, API plus database, in both regions. Geo-DNS routing guarantees a European user's phone only talks to the European server, giving 10 ms latency.

**The core challenge.** If the US and EU databases act independently, a user travelling from New York to London sees an empty cart.

**The objective.** Build an active active multi region architecture. Users read and write to their local regional database instantly, and the databases asynchronously replicate across the ocean in the background, mathematically merging conflicts when concurrent updates occur.

---

## Functional requirements

**Mutate.** Add, update the quantity of, or remove items from the cart.

**Read.** Fetch the fully hydrated cart state instantly.

**Sync.** Persist the cart across regions in the background, asynchronously.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | 100,000 global read/write QPS, roughly 2:1 read to write |
| Performance | local gateway to database write latency under 10 ms at p99 |
| Availability against consistency | strict availability. If the transatlantic cable is cut, both regions must keep taking orders independently. We completely sacrifice synchronous consistency for eventual consistency |
| Concurrency | safe cross region merge conflicts, for example a user modifying their cart on a US VPN and a UK cellular network simultaneously |
| Edge cases | the resurrected item problem, where replication delays make deleted items reappear |

---

## The architecture

```text
======================= GLOBAL EDGE ROUTING ==========================

                                +-------------------------+
    US User (Latency: 10ms) --> | GEO-DNS ROUTER          | <-- EU User (10ms)
                                +-------+---------+-------+
                                        |         |
============= US-EAST-1 ================|=========|====== EU-WEST-1 =========
                                        v         v
             +--------------------------+         +--------------------------+
             | API GATEWAY (US-EAST)    |         | API GATEWAY (EU-WEST)    |
             | (Validates JWT)          |         | (Validates JWT)          |
             +------------+-------------+         +-------------+------------+
                          |                                     |
                          v                                     v
             +--------------------------+         +--------------------------+
             | CART SERVICE (Node.js)   |         | CART SERVICE (Node.js)   |
             | (Stateless K8s Fleet)    |         | (Stateless K8s Fleet)    |
             +------------+-------------+         +-------------+------------+
                          |                                     |
                          v                                     v
             +--------------------------+         +--------------------------+
             | DYNAMODB (US-EAST TABLE) |         | DYNAMODB (EU-WEST TABLE) |
             | (Active Master 1)        |         | (Active Master 2)        |
             +------------+-------------+         +-------------+------------+
                          |                                     |
                          |      ASYNC WAL REPLICATION NETWORK  |
                          |      (DynamoDB Global Tables)       |
                          +-------------------------------------+
```

---

## The happy path

**1. DNS routing.** A user in London opens the app. The geo-DNS router checks their IP and resolves the domain to the EU gateway. No ocean was crossed.

**2. Local write.** The service writes to the local EU database, which commits to disk and returns success. The server returns `200 OK`. Total time is roughly 10 ms.

**3. The WAL stream.** The database pushes the change event to its internal write ahead log.

**4. Async sync.** A background replication process reads the WAL and sends the payload over the internal backbone to the US, executing the identical write. Average replication lag is roughly 1 second, and the user never waited for this step.

---

## The split brain conflict

1. A massive outage cuts connectivity between US and EU, so the replication network is dead.
2. A user has a VPN routed to the EU but their phone is routed to the US.
3. In the US they change the quantity to 2. In the EU they change it to 3.
4. Both regions accept the write, choosing availability over consistency.
5. Ten minutes later the network heals, the replication streams cross simultaneously, and we have a conflict.

---

## API design

We use `PUT` because cart item updates must be idempotent. If the user clicks add 5 times due to lag, it should resolve to the exact final state, not plus 5 items.

**Endpoint.** `PUT /v1/carts/me/items/{sku_id}`

**Headers.** `Authorization: Bearer <JWT>` and `X-Client-Timestamp: 1691234567890`, used as a fallback for conflict resolution.

```json
{
  "action": "set_quantity",
  "quantity": 2,
  "client_mutation_id": "mut_1122"
}
```

```json
{
  "cart_id": "usr_999",
  "sku_id": "macbook_pro_m3",
  "quantity": 2,
  "server_timestamp": 1691234567895,
  "sync_status": "PENDING_GLOBAL"
}
```

---

## Why DynamoDB and not Postgres or Mongo

Building an active active multi master database is the hardest problem in distributed systems.

In PostgreSQL both masters generate the same primary keys, and syncing them corrupts the database. Standard MongoDB is strictly single master, a primary with replicas.

To achieve true multi master replication you need a database natively built for it. In open source that is Apache Cassandra. In managed cloud that is DynamoDB Global Tables. DynamoDB eliminates the operational overhead of managing Cassandra clusters, ring topologies and manual anti entropy repairs.

### The schema

**The junior trap.** A junior engineer stores the entire cart as a single JSON document, `Payload: { items: [...] }`.

**Why it fails.** If you sync a single massive JSON blob, and the user adds item A in the US and item B in the EU, replication makes one document overwrite the other. You lose one of the items.

**The solution: item level granularity.** Store every cart item as its own physical row.

**Table `global_carts`.**

| Field | Value |
| --- | --- |
| Partition key | `cart#<user_id>`, for example `cart#usr_999` |
| Sort key | `item#<sku_id>`, for example `item#macbook_pro` |
| `quantity` | number |
| `updated_at` | number, epoch milliseconds generated by the server |
| `is_deleted` | boolean, the tombstone flag |

---

## Conflict resolution: LWW against CRDTs

When a network split heals, how do we merge concurrent updates to the same item, where the US says quantity 2 and the EU says 3?

### Last write wins, native to DynamoDB and Cassandra

The database looks at the `updated_at` server timestamp of both writes, and whichever millisecond is higher silently overwrites the other.

Incredibly simple, but you can lose data. If the US changes quantity to 5 and the EU changes it to 2, and the EU write happened 1 millisecond later, the final state is 2.

### CRDTs, conflict free replicated data types

We do not store absolute numbers, we store increments. The cart base is 0, the US sends `+1`, the EU sends `+2`. When replication merges, the algorithm applies all increments regardless of order: `0 + 1 + 2 = 3`.

This gives mathematical perfection with zero data loss. But it requires a highly specialised database, drastically increasing engineering complexity over native LWW. For standard e-commerce, LWW is the accepted business trade off.

---

## The resurrected item trap

**The scenario.** A user has a phone in their cart. In the US they click remove, a hard delete. 100 ms later, in the EU, they update the quantity to 3.

**The failure.** The US sends a `DELETE` to the EU, and the EU sends an `UPDATE` to the US. Because the row was hard deleted in the US, the incoming `UPDATE` acts as an `INSERT`. The deleted item comes back from the dead.

**The solution: tombstones.** Never execute a real `DELETE` on a distributed table. When a user removes an item, execute `UPDATE is_deleted = true AND updated_at = <now>`.

When the replication streams cross, the database compares the two timestamps. Since the tombstone timestamp is newer than the update timestamp, the tombstone wins and the item stays deleted.

---

## Follow up questions

### Clock drift

**Q.** You rely on server timestamps for last write wins. What if the US server clock runs 5 seconds faster than the EU clock?

**A.** Clock drift is the Achilles heel of LWW. If the US server is 5 seconds fast, US writes incorrectly win conflicts against newer EU writes.

To mitigate this we run a strict NTP daemon such as Chrony on all servers, syncing to a highly precise atomic clock source. That keeps clocks accurate to within single digit milliseconds. If absolute precision is required beyond that, we would abandon LWW and implement vector clocks.

### Cache invalidation across regions

**Q.** If a Redis cache sits in front of DynamoDB in the EU, how does it know the US updated the database?

**A.** A cache invalidation worker. Attach a serverless function or worker to the EU DynamoDB stream. When the EU table receives the replicated write from the US, it triggers the stream, and the worker executes `DEL cart#usr_999` against the EU Redis cluster. The next request results in a cache miss, forcing a fetch of the freshly synced data.

### Fifty rows per cart

**Q.** If a user adds 50 items, your schema creates 50 rows. Does fetching the cart require 50 separate reads?

**A.** No, because of the schema design. By using a shared partition key and sorting items via the sort key, the database physically stores all 50 rows contiguously on the same SSD block. A `Query` command fetches the entire block in a single highly performant sequential disk read.

---

## Why the whole stack lives in one cloud

If DynamoDB is the only piece doing the heavy lifting, why not run the compute elsewhere and just call DynamoDB via its API? Five reasons.

**1. Data gravity and the 10 ms requirement.** If your compute is in one cloud and the table in another, every read and write traverses the public internet or an interconnect, adding 2 to 20 ms subject to routing fluctuations. Co locating compute with the database partitions keeps it on the internal network, guaranteeing single digit milliseconds.

**2. The private transatlantic backbone.** Major providers do not route inter region traffic over the public internet. They own private custom built transatlantic fibre. That minimises jitter, reduces packet loss, and keeps replication lag as close to the speed of light as possible, shrinking the split brain conflict window.

**3. Ecosystem glue.** Inside the cloud you map a serverless function directly to a database stream in a few lines of infrastructure as code, and the provider handles polling, scaling and retries. Outside, you must build, deploy and monitor a custom fleet of workers long polling that stream API over the internet.

**4. Atomic clock precision.** Local compute nodes have direct access to the provider's time sync service via a link local address, connecting to a fleet of redundant satellite connected atomic clocks in every region. Achieving that level of NTP synchronisation across a hybrid cloud is notoriously difficult and prone to network jitter.

**5. The egress tax.** Cloud providers let data in for free but charge heavily to take it out. At 100k QPS with a 2:1 read to write ratio, cross cloud egress fees would quickly bankrupt the project.

> [!tip] The verdict
> You are not using one cloud because its DNS or gateway is magically better. You are using it because once your data layer dictates a specific cloud, physics and economics force your synchronous compute layer to live in the same house.
