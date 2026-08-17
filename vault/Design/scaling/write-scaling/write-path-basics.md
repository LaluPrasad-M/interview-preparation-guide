# Write Path Basics

> [!tldr]
> Write throughput is fundamentally limited by durability guarantees, batching overhead, and coordination between concurrent writers sharing the same data.

Part of [[write-scaling]].

---

## Stage 0: the simple write system

`Client -> API -> PostgreSQL`, used for comment posting, likes, signups, orders, messages and analytics events.

At small scale this architecture is good. The maturity point is: do not prematurely introduce Kafka, sharding, buffering or distributed transactions. PostgreSQL already handles transactions, concurrency, indexes, MVCC and durability extremely well at moderate scale.

**The first realisation.** A write is not merely `INSERT INTO ...`. Internally the DB must acquire locks, allocate transaction metadata, modify heap pages, update indexes, generate WAL, flush durability logs, maintain MVCC visibility and replicate changes. Writes are significantly more expensive than reads.

---

## Stage 1: WAL and durability bottlenecks

**Write ahead logging.** Before modifying the actual data pages, the database first writes the change into the WAL. This exists for crash recovery, durability and corruption prevention. If a crash occurs, the database replays the WAL to recover state.

**The production insight.** At high write throughput the major bottleneck becomes WAL flush latency, not merely CPU usage.

**`fsync()`.** The database eventually forces the OS to flush writes to durable storage. This is necessary because RAM is volatile, the OS page cache is volatile, and crashes lose memory. It introduces storage durability latency as a core bottleneck.

At high scale, the durability guarantees themselves limit throughput. That is the first big mental shift of write scaling.

---

## Stage 2: batching and write amplification

**Why batching appears.** If every write individually performs a WAL append plus an fsync, it is extremely expensive. Batching multiple writes together amortises one fsync across many writes, massively improving throughput.

**The core systems principle.** Amortise fixed costs across many operations. This appears everywhere: databases, Kafka, networking, distributed systems, storage engines.

**The tradeoff.** Batching improves throughput but worsens latency and potentially the durability window. A crash before flush means more data loss is possible. That creates the core tension between throughput and durability guarantees.

**Index write amplification.** During read scaling indexes looked beneficial. During write scaling they become expensive, because every insert or update must modify the heap, update every index, rebalance B trees and generate additional WAL.

Write amplification means one logical write becomes many physical writes.

> [!warning] The biggest indexing realisation
> More indexes improved reads. More indexes reduce write throughput. This is one of the most important database tradeoffs in backend engineering.

**Concurrency pressure begins.** Multiple users update the same shared state: counters, balances, inventory, bidding, wallets. Now the system experiences row locks, contention, waits and transaction conflicts. Writes to the same shared state serialise somewhere, which is one of the deepest distributed systems truths.

---

## Stage 3: lock contention and concurrency collapse

This is the first major transition from storage bottlenecks into coordination bottlenecks.

Multiple writers target the same shared state: wallet balances, seat booking, counters, likes, bidding systems, stock updates, inventory, payment processing.

**The truth this stage teaches.** Write scalability is fundamentally limited by coordination.

### The classic wallet example

Balance is 1000. Two concurrent deductions of 700 and 500 both read 1000 before either writes. That is a race condition.

This teaches something deeper: databases are not merely storage systems. They are shared state coordination systems.

To preserve correctness the database introduces row level locks, so transactions serialise safely and correctness is preserved. But the bottleneck changes again. Earlier the problem was storage throughput; now the problem is waiting.

This reconnects to read scaling: queues form again, retries amplify load, p99 explodes, occupancy increases and connection pools saturate. But now the root cause is shared state coordination instead of read overload.

> [!tip] The recurring pattern
> Many large scale failures are fundamentally queueing failures. Only the source of waiting changes.

### Pessimistic locking

Assumes conflicts are likely and locks immediately. Good for banking, ticket booking, inventory and payment correctness. It introduces waiting, lock queues, occupancy collapse and deadlocks.

### Optimistic locking

Emerged as a reaction to blocking. Assumes conflicts are rare and validates the version during commit, which dramatically reduces waiting. Excellent for profile updates, metadata edits and low conflict systems.

Under high contention, optimistic locking fails differently. Instead of a waiting collapse, the system suffers retry churn collapse, because transactions constantly fail version checks and retry.

The interview insight: the same coordination problem can fail through different amplification mechanisms.

### Hotspotting

Throughput depends not only on volume but also on distribution.

This connects back to Redis hot keys, hot Kafka partitions, viral celebrity traffic, uneven shards and hot DB rows. It is where the whole distributed systems worldview starts becoming unified.

### The evolution so far

```text
Simple writes
-> durability overhead
-> WAL/fsync bottlenecks
-> batching
-> write amplification
-> index maintenance cost
-> shared-state contention
-> lock queues
-> retry amplification
-> hotspotting
```
