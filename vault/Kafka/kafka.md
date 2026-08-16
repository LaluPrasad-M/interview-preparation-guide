# Kafka

> [!tldr]
> Kafka is a durable append only log, not a queue. Nearly every Kafka question reduces to partitions, offsets, or ordering.

---

## Core mechanics

| Note | Covers |
| --- | --- |
| [[internals]] | components, storage model, the end to end flow, delivery semantics, throughput design |
| [[partitioning]] | partitioning strategies, choosing keys, hot partitions, the danger of increasing partitions |
| [[consumer-groups-and-offsets]] | the golden rule, broadcast, auto against manual commit, deduplication |
| [[rebalancing]] | the group coordinator, assignors, eager against cooperative, rebalance storms |
| [[replication]] | replication factor choices, ISR, acks, why replication is not parallelism |

---

## Operations

| Note | Covers |
| --- | --- |
| [[lag-and-dead-letter-queues]] | the lag investigation framework, poison messages, retry topics, DLQs, metrics |
| [[polling-and-pausing]] | why you cannot sleep in a consumer, the pause and resume delayed retry pipeline |
| [[log-compaction]] | keeping the latest value per key, and where that matters |

---

## Design

| Note | Covers |
| --- | --- |
| [[topic-design]] | topics from business boundaries, ordering as a partition problem |
| [[kafka-vs-rabbitmq]] | when each one wins |
| [[websocket-bridge]] | Kafka to Redis to WebSocket fan out without rebalancing storms |
