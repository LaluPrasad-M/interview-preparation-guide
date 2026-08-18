# Async Processing And Queue Decoupling

> [!tldr]
> Moving slow work off the request path, and what breaks once a queue sits between the two halves.

Part of [[service-layer]].

---

## Stage 5: async processing and queue decoupling

**The core realisation.** Not every operation belongs in the critical path.

A critical path is the minimum set of work required before returning a response. Anything outside it becomes a candidate for Kafka, queues, asynchronous consumers and background processing.

**What is the critical path?** In an e-commerce checkout, some operations must complete before success can be returned: payment authorisation, inventory reservation, order creation. Without these the order is not actually complete, so they usually stay synchronous.

**What should leave it?** Email notifications, SMS notifications, analytics updates, recommendation refreshes, search indexing, audit processing. These are important but they do not determine whether checkout succeeded.

### Architecture evolution

Initially:

```text
Checkout
-> Payment
-> Inventory
-> Notification
-> Analytics
-> Search
```

Every dependency adds latency, failure risk, queueing risk and retry risk. Eventually:

```text
Checkout
-> Payment
-> Inventory
-> Kafka
```

then Kafka fans out to the Notification Consumer, Analytics Consumer, Search Consumer and Recommendation Consumer.

**The biggest benefit.** Before decoupling, checkout latency was payment plus inventory plus notification plus analytics plus search. After decoupling it is payment plus inventory plus the Kafka publish. That dramatically reduces response time, tail latency, dependency count and failure surface area.

### Kafka's real role

One of the biggest misconceptions is that Kafka is just a queue. In large architectures Kafka often acts as a temporal decoupling layer.

The producer says "I have recorded the event, my responsibility is complete". Consumers decide later when and how to process it. Producer and consumer lifecycles become independent.

**Temporal decoupling.** The producer and consumer do not need to be alive, healthy, or fast at the same time. Without it, the producer waits for the consumer. With it, the producer records the event and leaves.

> [!warning] Async does not remove work
> Many engineers subconsciously think async equals cheaper. It is not. Async does not remove work, it simply moves work. Before, the user waits. After, the queue waits. The work still exists, which is why consumer lag, queue depth, processing throughput and backlog growth become critical operational metrics.

### Eventual consistency

Checkout completes but the notification consumer has not processed the event yet, so temporarily the order exists and the notification is absent. The system disagrees with itself. A few seconds later the consumer catches up and the state converges.

You will keep seeing this concept in Kafka, Redis, [[cqrs|CQRS]], replication, projections and event driven systems.

**Async failures are harder to debug.** A synchronous failure means the request failed immediately, which is simple. An asynchronous failure means the request succeeded and the consumer failed 30 minutes later. Now engineers need tracing, replay, dead letter queues, lag monitoring and event correlation.

---

