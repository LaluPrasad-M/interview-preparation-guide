# Distributed Transactions, Saga and Outbox

> [!tldr]
> A business transaction is usually bigger than a database transaction. That one sentence explains why distributed systems are difficult.

---

## The shift in focus

Earlier stages solved latency, throughput, retries, failures, queues and observability. This one asks a completely different question: how do multiple services complete a single business operation correctly?

Scalability problems make systems slow. Correctness problems make systems wrong. Wrong is often more dangerous than slow.

---

## The core realisation

> [!tip] The sentence that explains everything
> A business transaction is usually bigger than a database transaction.

In a monolith:

```sql
BEGIN;
UPDATE inventory;
INSERT order;
INSERT payment;
COMMIT;
```

Everything succeeds together, or everything rolls back together. Life is simple.

### Why distributed systems break this model

Suppose you now have an Order Service, Payment Service, Inventory Service and Notification Service, each owning its own database.

Payment succeeds. Inventory fails. How do you roll back the payment? You cannot simply issue `ROLLBACK;`, because the Payment Service has already committed. That is the fundamental distributed transaction problem.

Database transactions solve single database consistency. They do not solve cross service consistency. Interviewers love asking this distinction.

---

## Two phase commit, and why it is rare

Historically systems attempted to solve this with the two phase commit protocol. The coordinator asks everyone "can you commit?", all participants reply "yes", and then the coordinator says "commit". This provides strong consistency and sounds perfect.

The biggest problem is that availability suffers. It is a blocking protocol, it has coordinator failure problems, slow participants delay everyone, and it scales poorly. Modern internet scale architectures generally avoid 2PC whenever possible.

If asked why large internet companies do not use 2PC everywhere, the answer is: it trades too much availability and scalability for global consistency.

**The modern approach.** Eventual consistency plus compensation, instead of a global distributed transaction. That leads directly to the Saga pattern.

---

## The Saga pattern

Instead of one giant transaction, break the workflow into steps, each committing independently.

```text
Reserve Inventory
   |
Charge Payment
   |
Create Order
   |
Send Notification
```

Every step becomes its own local transaction. This is the dominant pattern in modern distributed systems.

### Saga does not roll back, it compensates

This distinction is extremely important. Many engineers say "roll back payment", which is usually incorrect.

**Rollback** means the database never committed. **Compensation** means the database committed, and you now perform another operation to logically undo it.

Wrong thinking: charge payment, roll back payment. Real world thinking: charge payment, issue refund. A refund is a compensating transaction, not a rollback.

**A worked compensation.**

```text
Inventory Reserved
   |
Payment Charged
   |
Order Creation Failed

Compensation:
Refund Payment
   |
Release Inventory
```

You are not rewinding time. You are creating new business operations that restore correctness.

### Orchestration against choreography

**Orchestration.** A dedicated coordinator exists, for example an Order Orchestrator, which controls the workflow: reserve inventory, charge payment, create order, send notification.

Advantages: easy visibility, easy debugging, easy monitoring. Disadvantages: a central coordinator that can become a bottleneck.

**Choreography.** No coordinator. Services communicate via events: `OrderCreated` fires, the Inventory Service reacts, the Payment Service reacts, the Notification Service reacts.

Advantages: loose coupling, independent services. Disadvantages: harder debugging, harder workflow visibility.

Which to choose: complex business workflows lean toward orchestration, simple event chains lean toward choreography.

---

## The outbox problem

Suppose:

```js
await createOrder();
await kafka.publish();
```

What if the DB write succeeds and the Kafka publish fails? Now the order exists and the event is missing. That is a correctness bug and a very common interview scenario.

### Transactional outbox

Instead of writing the order and then publishing the event, write the order and write an outbox event inside the same database transaction.

```sql
BEGIN;

INSERT INTO orders(...);

INSERT INTO outbox_events(...);

COMMIT;
```

Now the order and the event are committed atomically.

### The outbox relay

A background worker continuously reads the outbox table, publishes the Kafka event, and marks the event processed.

```text
                    +-- Business Table
Request -> DB Txn --+
                    +-- Outbox Table
                           |
                           v
                       Publisher
                           |
                           v
                         Kafka
```

This guarantees there is no order without an event, which is the entire goal. It is one of the highest frequency senior backend interview topics.

Without an outbox, a DB success plus a Kafka failure creates lost events. With an outbox, the DB success plus the outbox success means the Kafka publish eventually succeeds. A huge difference.

### Two ways to relay the records

**Polling publisher.** A worker periodically queries:

```sql
SELECT *
FROM outbox_events
WHERE status = 'PENDING'
LIMIT 100;
```

It publishes them to Kafka and marks them processed. Simple, and a perfectly valid outbox implementation.

**CDC or change streams.** Instead of polling, a tool like Debezium watches the database transaction log, sees inserts into the outbox table, and publishes them.

```text
Outbox Table
     |
     | DB transaction log
     v
CDC (for example Debezium)
     |
     v
Kafka
```

This gives lower latency and avoids repeated polling, but adds infrastructure and operational complexity.

> [!warning] Keep these two ideas separate
> The outbox pattern solves the dual write problem. CDC or polling solves how you relay the outbox records to the message broker. They are different layers.

For interviews, default to outbox plus polling unless scale or latency justifies CDC. Do not throw Debezium into a moderate scale system merely because you are using an outbox.

> [!warning] Outbox is not exactly once
> The relay can publish an event and crash before marking it processed, causing a duplicate publish. Consumers still need to be idempotent.

---

## Idempotency returns again

One of the most beautiful observations across this whole roadmap: almost every advanced distributed systems topic eventually comes back to idempotence.

Because retries happen, consumers restart, Kafka replays happen, outbox relays retry and network failures occur, consumers must safely handle duplicates.

Common approaches: `UNIQUE(order_id)`, or tracking tables keyed on `processed_event_id`. This is production critical.

---

## The complete modern checkout flow

```text
Checkout Request
   |
Order Service
   |
BEGIN TX
    Save Order
    Save Outbox Event
COMMIT
   |
Outbox Relay
   |
Kafka
   |
Inventory Consumer
   |
Payment Consumer
   |
Notification Consumer
```

Notice how many previous stages appear: Kafka, async processing, retries, idempotency, consumer lag, eventual consistency. This is where all those concepts begin converging.

---

## How this connects to earlier stages

| Earlier stage taught | This stage teaches |
| --- | --- |
| move work asynchronously using Kafka | how to do that safely |
| services communicate with each other | how those services maintain business correctness |
| consumer lag and queue growth | what happens when those consumers execute business workflows |
| how to observe systems | what correctness failures to observe |

---

## Common questions

What is a distributed transaction? Why is it harder than a DB transaction? What is two phase commit? Why is 2PC uncommon in large scale systems? What is a Saga? What is a compensating transaction? Difference between rollback and compensation? Orchestration against choreography? What is the outbox pattern? Why do we need it? How do you guarantee reliable Kafka event publishing? Why is idempotency critical in event driven systems?

These are among the highest frequency senior backend interview questions.

---

## The takeaways

A business transaction is larger than a database transaction. Distributed consistency is harder than local consistency. Modern systems prefer compensation over global rollback. Saga is the dominant distributed workflow pattern. Compensation is not rollback. Outbox solves the DB write and Kafka publish consistency gap. Idempotency is mandatory in event driven systems. Eventual consistency is usually accepted for scalability.

> [!tip] The single most important sentence
> Distributed systems achieve correctness through coordination, compensation, idempotency and eventual consistency, not through one giant transaction.

---

## The interview answer for Saga

"Saga pattern is used to manage distributed transactions across multiple microservices without relying on a global transaction like 2PC. Instead of a single ACID transaction, it breaks the workflow into a sequence of local transactions, where each step has a compensating action to undo it in case of failure.

For example, in an order processing system, if payment succeeds but inventory reservation fails, the saga triggers a compensation step like refunding the payment to maintain consistency.

Sagas can be implemented using choreography, where services communicate via events, or orchestration, where a central service manages the workflow. This approach improves scalability and fault tolerance in distributed systems."

---

## Where each tool fits

| Problem | Solution |
| --- | --- |
| Concurrent writes in a DB | locking |
| Distributed transactions | Saga |
| Message duplication | idempotency |
| Ordering issues | partitioning |
