# Kafka Internals

> [!tldr]
> Kafka is a distributed, replicated, append only commit log. Partitions give scaling, replication gives fault tolerance, consumer groups give parallelism.

---

## What Kafka actually is

A massive source of confusion is treating Kafka like a traditional pub/sub system. Kafka is a distributed durable log.

Internally it stores data in segment files, uses a leader-follower architecture and supports exactly once semantics. It achieves extremely high throughput through sequential disk writes, page cache and zero copy.

---

## Key components

| Component | What it does |
| --- | --- |
| Producer | writes messages to topics |
| Broker | a Kafka server that stores data |
| Topic | a logical stream of messages |
| Partition | an ordered, append only log, and the unit of parallelism |
| Consumer | reads messages from topics |
| Consumer group | provides horizontal scaling |

A topic is the sum of its partitions.

---

## The concepts, in plain English

| Concept | What it means | Why it matters |
| --- | --- | --- |
| Topic | a named stream or channel of messages, a message category | organises data by purpose, for example `user-signup`, `orders`, `audit-logs` |
| Partition | each topic is split into one or more partitions, each an append only immutable log | enables parallelism and scalability |
| Offset | each message inside a partition gets a sequential number 0, 1, 2 and so on | consumers track where they are, which supports replay, fault tolerance and per partition ordering |
| Broker | one server in a Kafka cluster that stores some partitions | Kafka scales horizontally by adding brokers |
| Leader and followers | for each partition, one replica is leader and the rest are followers, and the leader handles all reads and writes | if the leader fails a follower is promoted, so no data loss and high availability |
| In sync replicas (ISR) | the subset of replicas up to date with the leader | only healthy replicas are used for failover, preventing data loss on replica lag |
| Segments and index files | each partition log is stored as a sequence of segment files such as `000000000.log` and `000000000.index` | efficient disk I/O, fast lookups, manageable file size |
| Commit log | Kafka appends sequentially and old data stays until retention removes it | append only sequential writes make Kafka fast and simplify replay |
| Consumer group and offsets | a set of consumers sharing the read load, each group tracking its own offset per partition | parallel, fault tolerant, replayable consumption |
| Retention policy | Kafka auto deletes old data based on time or size | prevents unbounded disk usage |

---

## Storage model

Messages are written to disk sequentially, which is fast because of the OS page cache. Data is stored in segments, and old segments are deleted based on the retention policy. Kafka uses zero copy transfer via `sendfile()` for efficiency.

---

## The end to end flow

```text
Producer  --> Broker (Leader of Partition X) --> Append to log segment file --> Followers replicate --> Message committed
                                                                                     |
                                                                                     v
Consumer (in Consumer Group)  --> Fetch offset N --> Read from log --> Process message --> Commit offset
```

1. The producer sends messages and Kafka picks a partition, either by key or by round robin.
2. The broker writes the message to the append only log with a fast sequential disk write.
3. The leader replicates to followers across brokers.
4. Once replicated to enough replicas, depending on the `acks` config and ISR, the produce ack is returned.
5. The consumer reads at its own pace using its stored offset, and can replay or reprocess as needed.

---

## Delivery semantics

| Semantic | Guarantee |
| --- | --- |
| At most once | possible loss, no duplicates |
| At least once | no loss, possible duplicates |
| Exactly once | no loss, no duplicates, requires Kafka Streams or idempotent producers plus transactions |

---

## What this design buys you

**High throughput.** Append only logs plus sequential disk I/O plus batching gives millions of messages per second.

**Scalability.** Partitions plus multiple brokers allow horizontal scaling.

**Fault tolerance and durability.** Replication and in sync replicas ensure no data loss if brokers die.

**Replayability.** Because the log is retained, consumers can re read data anytime for audit, debugging or reprocessing.

**Parallel processing.** Multiple partitions and consumer groups allow concurrent producers and consumers without interference.

---

## What Kafka achieves high throughput through

Sequential disk writes, page cache utilisation, zero copy I/O, batching on both producer and consumer, compression (gzip, snappy, lz4, zstd), and partition based parallelism.

---

## Trade offs to watch

Ordering is guaranteed only per partition, and messages across partitions are independent. Designing good partition keys matters, because bad keys create hot partitions. Stronger durability, meaning `acks=all` plus high replication, adds latency. Because Kafka retains logs, disk usage needs management through compaction or deletion policies.

---

## Retention and compaction

Kafka is not a queue that deletes on consumption. Retention policies are time based (`log.retention.hours`), size based, or log compaction, which keeps the latest record per key. See [[log-compaction]].

---

## Common operational terms

**Broker** is a server instance. **Cluster** is multiple brokers. **Zookeeper or KRaft** holds metadata and the controller. New clusters use KRaft, with no Zookeeper. **Controller broker** manages partition leadership. **Rebalancing** is redistribution of partitions when the consumer group changes.

---

## Common usage patterns

Event sourcing, log aggregation, change data capture using Debezium, streaming ETL pipelines, microservice communication, and real time analytics.

---

## Common performance bottlenecks

Too many partitions per broker. Small batch sizes that lower throughput. Sync flush on the producer without batching. ISR shrinkage due to network latency. Large message size that causes memory pressure.

---

## Quick best practices

Use idempotent producers to avoid duplicates. Use `acks=all` plus proper replication for durability. Tune batch sizes and linger time for throughput. Keep message size small, because Kafka is optimised for many small messages. Partition with keys where ordering is required.

---

## When to introduce Kafka

> [!tip] The interview line
> I would introduce Kafka when the workflow does not require immediate synchronous processing, the throughput is high, multiple downstream systems need the same event, and I want to decouple producers from consumers. Kafka also helps absorb traffic spikes, provides backpressure handling, improves fault isolation, and allows independent scaling of consumers.

---

## Kafka Streams, briefly

Kafka Streams is a Java library for stream processing that provides windowing, joins, state stores and exactly once semantics. It uses RocksDB for local state.

---

## Mini flash Q and A

| Question | Answer |
| --- | --- |
| Ordering guarantees? | only within a single partition |
| When does a consumer commit an offset? | depends on config: manual, auto commit, or an external store |
| Dead letter queues? | not built in, implemented as separate topics |
| Backpressure? | handled by consumer lag plus throttle configs |
| Difference between a queue and Kafka? | Kafka stores for retention, and consumers do not delete on read |

---

## The memorisable summary

> [!tip] Say this in an interview
> Kafka stores events in append only logs per partition, where each event gets a sequential offset. Partition data is replicated across brokers, a leader plus followers, ensuring durability and availability. Producers write to a partition leader, consumers read at their own pace using offsets, and consumer groups allow parallel independent consumption. Log based storage plus partitioning plus replication makes Kafka scalable, fault tolerant and replayable.

---

## The isolation of concern

Topics break into partitions, so data is sharded for parallel processing. Consumer groups mean each microservice processes all messages independently. Offsets are isolated: billing may be at offset 120, notification at 300, and analytics may replay from 0.

Failure is isolated too. If billing crashes, notifications keep working and analytics keeps streaming. Throughput is isolated: if analytics is slow, only analytics slows down.

This is Kafka's biggest strength, decoupled and isolated event processing.
