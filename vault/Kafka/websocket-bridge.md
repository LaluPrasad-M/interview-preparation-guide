# The Kafka, Redis and WebSocket Bridge

> [!tldr]
> Connecting thousands of ephemeral edge servers directly to Kafka is an anti pattern. Put a small stable bridge between them.

---

## Why direct connection fails

Kafka hates consumers that constantly spin up and down, which is exactly what WebSocket servers do as they are added and removed. Every membership change triggers [[rebalance-storm|rebalancing storms]] that halt message processing.

See [[rebalancing]] for why the pauses happen.

---

## The hybrid model

To achieve a massive fan out, such as sending a global alert to millions of connected clients, modern architectures separate durability from delivery.

1. **Ingestion, Kafka.** Your backend produces the global alert event to a Kafka topic. This guarantees the event is never lost, even if downstream systems are offline.

2. **The bridge, stable consumers.** A small, stable cluster of workers, for example 10 nodes, sits in a single Kafka consumer group and reads the topic. Because there are only 10 stable nodes, Kafka never experiences rebalancing storms.

3. **The fan out, Redis pub/sub.** The bridge workers publish the Kafka message to a Redis channel. Redis keeps no history and tracks no offsets. It is optimised purely for blindingly fast in memory distribution.

4. **Ephemeral delivery, WebSockets.** Your 5,000 WebSocket servers subscribe to the Redis channel. They receive the message instantly and push it down the TCP pipes to end users.

```text
Backend
   |
 Kafka topic
   |
Bridge workers (10 stable nodes, one consumer group)
   |
 Redis pub/sub channel
   |
5,000 WebSocket servers
   |
 End users
```

---

## Why this wins

You get the absolute reliability of Kafka for your core backend data, paired with the lightweight, zero overhead routing of Redis for your volatile edge servers.
