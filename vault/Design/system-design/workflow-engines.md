# Workflow Engines

> [!tldr]
> Kafka is event transport. A workflow engine is the workflow brain. They solve different problems, and long running stateful processes need the second one.

---

## When you reach for one

A workflow engine such as Temporal fits when the process is a long running stateful workflow with many state transitions, cross service coordination, high volume, and a strong need for retries, resilience and resumability.

The core reasons: durable workflows where state is persisted rather than held in memory, automatic retries with configurable policies, failure recovery without manual compensation logic, and orchestration decoupled from business logic.

It can usually be added later as an add on, without rewriting the services underneath.

---

## The components

**Workflow.** It is deterministic code that describes what should happen, not how. It makes no direct database or network calls.

**Activity.** It is the actual business logic, meaning API calls, database writes and real work. Activities can fail, time out and retry.

**The server.** It persists workflow state and event history, schedules activities, and handles retries, timers and signals.

**Workers.** Workers are deployed alongside your services. They poll task queues and execute activities.

> [!tip] The key internal idea
> Workflow state is rebuilt by replaying history, so a crash does not lose progress.

An important framing point: services do not consume events directly, they run workers that poll task queues.

---

## Failure handling

**If an activity fails,** the engine retries automatically based on configured retry count, backoff strategy and timeout. No manual retry loops.

**If a worker crashes,** the activity is retried on another worker and the workflow resumes from the last successful step.

**If the server restarts,** state is already persisted and the workflow continues from where it stopped.

That is stronger than at least once messaging. It is stateful recovery.

---

## Scaling

Scaling is handled by horizontal scaling of workers, task queues acting as logical sharding, and workflow partitioning by a business key such as entity ID, customer ID or business unit.

> [!warning] What it scales
> The engine scales execution, not ingestion. Your producing service still controls event emission. The engine ensures controlled, reliable processing.

---

## Latency

A workflow engine is not ultra low latency. There is workflow scheduling latency and task queue polling delay.

That is usually fine, because long running business processes are not real time critical and reliability matters more than raw speed.

> [!tip] The interview line
> We optimised for correctness and resilience, not sub millisecond latency.

---

## Why not Kafka alone

Kafka is great for high throughput event streaming, loose coupling and fan out to multiple consumers.

But Kafka lacks workflow state, step level retries, built in resumability and long running orchestration.

So Kafka emits the events and the workflow engine manages the lifecycle orchestration. Kafka is event transport, the engine is the workflow brain.

---

## The closing statement

"A workflow engine was introduced as an add on because the system evolved into long running stateful workflows across services. Instead of building custom retry, state and recovery logic, it gave us durability, retries and resumability out of the box, while letting the underlying services stay loosely coupled and independently scalable."

---

## Where it sits in the NFR table

Long running reliability plus retries is one of the nine rows in [[nfr-decision-table]]. The database choice for that row is the engine's own durable state rather than a database you manage.

> [!tip] The lock-in insight
> If retries matter, state must live outside your service.
