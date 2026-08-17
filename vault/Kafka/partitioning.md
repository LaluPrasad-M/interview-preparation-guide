# Partitioning and Hot Partitions

> [!tldr]
> Choosing a partition key is really choosing what should stay ordered. That decision is a business decision, not a technical one.

---

## What partitioning determines

Partitioning determines which partition a message is written to. Kafka topics are divided into partitions:

```text
Topic
|-- Partition 0
|-- Partition 1
|-- Partition 2
+-- Partition 3
```

It is critical for scalability, ordering, parallel consumption, load balancing and throughput.

---

## Why partitions exist

**Parallelism.** Multiple consumers can process different partitions simultaneously.

```text
P0 -> Consumer A
P1 -> Consumer B
P2 -> Consumer C
```

**Ordering guarantee.** Kafka guarantees ordering only within a partition. If all events for `user-123` go to the same partition, then `login`, `cart`, `payment`, `logout` stay in order.

---

## Kafka default partitioning logic

**Case 1, the message has a key.** Kafka uses `hash(key) % numberOfPartitions`. For example `hash("user-123") % 4 = 2` sends the message to partition 2.

> [!tip] The important rule
> Same key means same partition. That is what preserves ordering for related events.

**Case 2, no key present.** Kafka uses round robin or sticky partitioning, depending on producer configuration and version.

**Sticky partitioning.** Modern producers temporarily stick to one partition to improve batching, compression, throughput and network efficiency, then switch periodically.

---

## The partitioning strategies

### Round robin

Messages are distributed evenly: `msg1 -> P0`, `msg2 -> P1`, `msg3 -> P2`.

It gives even distribution and good load balancing, but no ordering guarantee.

### Key based, the most common

```text
partition = hash(key) % partitions
hash = murmur2(bytes)
```

Suppose MurmurHash returns `-1853462912`. Kafka makes it positive:

```text
positiveHash = hash & 0x7fffffff
```

Suppose that becomes `294021736`. Then:

```text
partition = 294021736 % 10
```

So `order-123` always lands on P2. Ordering is preserved and related events are grouped, but there is hot partition risk.

### Custom partitioning

```js
if (region === "INDIA") return 0;
if (region === "US") return 1;
```

This is used for geo routing, tenant isolation and priority workloads.

---

## Choosing a good partition key

**Good keys** are high cardinality identifiers: `userId`, `orderId`, `accountId`, `rideId`, `deviceId`.

**Bad keys** are low cardinality fields: `country`, `status`, `city`, `tenantType`. These create skew.

| Property | Why it matters |
| --- | --- |
| High cardinality | better distribution |
| Stable | the same entity stays grouped |
| Business relevance | easier debugging |
| Ordering relevance | correct event sequence |

---

## The four questions framework

Whenever choosing a Kafka key, ask:

1. What entity needs ordering? `orderId`, `accountId`, `leadId`, `batchId`?
2. Can this key become extremely popular? `jobId`, `campaignId`, `cityId`?
3. Will one key receive 1000 times more traffic than another? If yes, that is hot partition risk.
4. Can I tolerate out of order processing? If yes, choose better distribution.

---

## The partition key follows the entity, not the event

The partition key is usually not chosen based on the event. It is chosen based on the entity whose state must remain consistent.

| Domain | State | Entity | Partition key |
| --- | --- | --- | --- |
| Inventory | stock count | product | `product_id` |
| Driver tracking | driver location | driver | `driver_id` |
| Food delivery | order lifecycle | order | `order_id` |
| Banking | account balance | account | `account_id` |

So `partition_key = order_id` guarantees that `ORDER_CREATED`, `PAYMENT_SUCCESS` and `ORDER_DELIVERED` remain ordered for that order.

---

## The hot partition problem

A hot partition is one partition receiving disproportionate traffic. For example `virat-kohli -> Partition 3` overloads only one partition.

**Symptoms.** Consumer lag, high broker CPU, uneven throughput, increased latency, disk and network imbalance.

**Causes.** A bad partition key, for example `country = INDIA` where millions hash to the same partition. Or natural traffic skew, for example a celebrity user.

> [!warning] Adding more consumers does not help
> Within a consumer group, one partition maps to exactly one consumer. Symptoms are one partition holding most of the lag, one consumer overloaded, and the other consumers mostly idle.

---

## Handling hot partitions

**1. Better partition key design, the best solution.** Prefer `userId`, `orderId`, `deviceId`. Avoid `country`, `status`, `region`.

**2. Key salting or bucketing.** Split one hot key into multiple logical keys. Instead of `user-123`, use `user-123-0`, `user-123-1`, `user-123-2`:

```js
key = `${userId}-${random(0, 3)}`
```

Traffic spreads across partitions, but you lose strict ordering. This is the classic ordering against scalability trade off.

**3. Increase partition count.** For example 8 to 32 partitions, which helps distribute many medium hot keys. But a single ultra hot key still maps to one partition, so this does not fully solve one massive hot key.

**4. Separate hot entities into dedicated topics.** For example `celebrity-users-topic` and `normal-users-topic`, which gives isolated scaling, dedicated consumers and independent tuning.

**5. Custom partitioner.**

```js
if (user.isCelebrity) {
  return randomPartition();
}
```

**6. Producer side batching.** Tune `linger.ms`, `batch.size` and `compression.type`.

**7. Consumer scaling.** Add more consumers, process asynchronously, and speed up downstream systems.

**8. Pre aggregation.** Instead of sending millions of raw click events, aggregate first to `user clicks = 200` and publish a summary.

---

## Monitoring hot partitions

Metrics: partition throughput, consumer lag, broker CPU, request latency, bytes per second. Tools: Prometheus, Grafana, Kafka Exporter, Burrow.

> [!warning] The Cruise Control insight
> LinkedIn Cruise Control rebalances partitions across brokers and optimises cluster resource usage. It does not redistribute messages across partitions. Hot keys stay hot. Very important interview point.

---

## Increasing partitions is not free

**Partition increase triggers a rebalance.** Adding partitions changes topic metadata, so Kafka must redistribute partitions among consumers.

**Increasing partitions changes key mapping.** Kafka routes on `hash(key) % partitionCount`:

```text
Before: hash(order123) % 8  = P3
After:  hash(order123) % 16 = P11
```

Same key, different partition.

**Historical ordering can break.** Before the increase, `ORDER_CREATED` and `PAYMENT_SUCCESS` might be in P3. After it, `ORDER_DELIVERED` might go to P11. Now one entity's history spans multiple partitions. This is the biggest danger of increasing partitions.

For strict ordering systems such as ledgers, banking, inventory and settlement, either overprovision partitions upfront, or create a new topic and migrate, instead of blindly increasing partitions.

> [!tip] The senior level reflex
> When somebody says "traffic doubled, let's increase partitions", the next question is automatically "do we care about historical ordering for existing keys?" If yes, increasing partitions is not a free operation.

---

## The logical shard trick

The problem is that `hash(key) % partitionCount` changes whenever the partition count changes. The solution is a fixed logical shard space:

```text
hash(key) % 1000
```

So `account123` always maps to `shard723`. Then a routing table maps `shard723 -> partition5`. Now Kafka partitions can change without changing shard ownership.

Logical shards decouple logical ownership from physical Kafka partitions, exactly like database sharding.

---

## Partitions determine maximum parallelism

```text
Maximum active consumers = number of partitions
```

With 12 partitions and 50 consumers, only 12 consumers actually work.

---

## Out of order events and version numbers

**The question.** We partitioned by a random key to avoid hot partitions, so events for the same lead now arrive out of order. We added version numbers. Is that enough?

**The answer.** Not necessarily. Version numbers help detect stale or missing events, but they do not recover lost intermediate transitions. If the business requires a complete audit trail, we need either ordering guarantees, event sourcing, or a mechanism to detect and recover missing events. Simply discarding older versions may preserve final state correctness but can lose historical state transitions.

---

## The core trade off

| Goal | Conflict |
| --- | --- |
| Ordering | reduces scalability |
| Scalability | may weaken ordering |
| Even load distribution | hard with skewed traffic |

> [!tip] The concise interview answer
> Kafka partitioning determines how messages are distributed across partitions using round robin, key based hashing, or custom partitioners. Key based partitioning preserves ordering for related events but can create hot partitions when traffic is skewed. Hot partitions are mitigated with better keys, salting, more partitions, custom routing, dedicated topics and monitoring. The major trade off is strict ordering against horizontal scalability.
