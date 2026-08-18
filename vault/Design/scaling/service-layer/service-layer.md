# Service Layer Failures, Stage by Stage

> [!tldr]
> Microservices distribute latency and failure across networks. The stages below trace how a healthy system degrades and what each defence actually protects.

---

## The biggest evolution

At the beginning, microservices look modular, clean, scalable and independently deployable:

```text
Client
-> API Gateway
-> Checkout Service
-> Payment Service
-> Inventory Service
-> Notification Service
```

Initially everything appears healthy. The deeper realisation across these stages is that microservices distribute latency and failure across networks, which is the foundation for latency amplification, retries, queue buildup, cascading failures and overload collapse.

---

## The parts

| Note | Covers |
| --- | --- |
| [[latency-and-retries]] | how synchronous chains amplify latency and retries multiply traffic |
| [[timeouts-and-circuit-breakers]] | overload protection, timeouts, backpressure, circuit breakers and bulkheads |
| [[event-loop-lag]] | what happens inside a Node.js process under sustained pressure |
| [[async-processing-and-queues]] | moving slow work off the request path, and what a queue changes |
| [[fanout-and-n-plus-one]] | one request becoming hundreds of downstream calls |
| [[memory-and-queue-collapse]] | memory leaks, exhausted pools, and a queue that stops draining |

---

## How the stages connect

| Stage | Teaches |
| --- | --- |
| 1 | latency propagates |
| 2 | retries amplify pressure |
| 3 | systems must reject work under overload |
| 4 | failures must be isolated before they spread |
| 5 | remove unnecessary work from the critical path |
| 6 | reduce the amount of work each request creates |
| 7 | understand what happens inside the process after pressure arrives |
| 8 | pressure remains in the system when resources are not released |

Notice how naturally the evolution progresses, from handling requests toward surviving failures. That transition is the entire purpose of the service layer.
