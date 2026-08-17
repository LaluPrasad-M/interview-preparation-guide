# Saga Pattern

> [!tldr]
> Distributed transactions are solved by breaking workflows into independent compensating transactions instead of relying on global ACID guarantees.

Part of [[distributed-transactions]].

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
