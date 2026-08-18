# Kafka against RabbitMQ

> [!tldr]
> RabbitMQ is a smart broker with dumb consumers and flexible routing. Kafka is a dumb log with smart consumers and enormous throughput.

---

## The comparison

| Feature | RabbitMQ | Apache Kafka |
| --- | --- | --- |
| Primary use case | task distribution, request reply, complex routing | event streaming, real time analytics, log aggregation |
| Model | push, the broker pushes messages to consumers | pull, consumers request batches of messages |
| Data retention | deleted after consumption by default | persistent and log based, retained for a set duration |
| Routing | highly flexible: direct, topic, fanout, headers | simple, based on topic and partition |
| Throughput | roughly 4k to 10k messages per second | roughly 1 million or more per second |
| Ordering | guaranteed per queue, with one consumer | guaranteed per partition |

---

## When to choose RabbitMQ

**1. Complex routing logic.** RabbitMQ supports direct, topic, fanout and headers exchanges. Patterns like `payment.*`, `notification.email` and `notification.sms` make it excellent for workflow engines, notification systems and job distribution.

**2. Low latency task queues.** It is commonly used for background jobs, async processing and task queues. A user uploads an image, a thumbnail job is queued, a worker processes the image.

**3. Request and reply messaging.** RabbitMQ supports RPC style messaging better. Kafka is not ideal for RPC.

**4. Fine grained acknowledgment.** Explicit ACK and NACK, dead letter queues, retry queues and per message [[ttl|TTL]], all useful for transactional workflows.

**5. Smaller scale systems.** It is often simpler operationally for medium throughput enterprise and internal systems.

**6. Strict consumer delivery semantics.** This is good when every task matters. Job execution tracking matters too, for example payment processing, email jobs and order workflows.

---

## When to choose Kafka

**1. Massive throughput.** It handles millions of events per second through distributed streaming, which makes it excellent for logs, telemetry, clickstreams and analytics.

**2. Event streaming architecture.** This is ideal when the events themselves are valuable. `OrderCreated`, `PaymentProcessed`, `InventoryUpdated` become permanent history.

**3. Replayability.** Very important. Kafka retains events and consumers can replay old ones. RabbitMQ is not designed for replay centric architectures.

**4. Event sourcing and [[cqrs|CQRS]].** It is excellent for rebuilding state, replaying events and audit trails. Huge in fintech.

**5. Independent consumer scalability.** Many consumer groups can independently process the same stream. An orders topic can feed analytics, fraud detection, a recommendation engine and the warehouse system, each keeping its own offset.

**6. Stream processing.** The Kafka ecosystem supports Kafka Streams, Flink and Spark Streaming. RabbitMQ is weaker here.
