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

## The parts

| Note | Covers |
| --- | --- |
| [[saga-pattern]] | two phase commit, the saga pattern and orchestration vs choreography |
| [[outbox-pattern]] | the transactional outbox, relays and the dual write problem |

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
