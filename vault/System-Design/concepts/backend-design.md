# Backend Design

> [!tldr]
> Where correctness and cost live. Users forgive a plain screen. They do not forgive lost data or a service that falls over when traffic doubles.

---

## What a good backend gives you

**It stays up as it grows.** A load balancer spreads requests across servers, and autoscaling adds servers when traffic climbs.

| Direction | Means | Catch |
| --- | --- | --- |
| **Horizontal scaling** | add more machines | usually the safer bet |
| **Vertical scaling** | give one machine more CPU and memory | one bigger machine is still one machine that can die |

**Services talk efficiently.**

| Choice | Reach for it when |
| --- | --- |
| gRPC | two services need low latency chatter |
| Kafka | a service should announce something happened and not care who listens |
| REST | ordinary request and response APIs |
| GraphQL | clients want to pick exactly the fields they need |

**It is hard to abuse.** Rate limiting caps how often one caller can hit you. JWT or OAuth proves who they are. Role based access control decides what they may do. Encryption protects data sitting in the database and data moving over the wire.

---

## What a bad one costs

> [!warning] Two failure shapes
> **Bottlenecks.** Code that stops and waits instead of moving on (blocking I/O), queries scanning more rows than they need, long jobs run inline while the caller waits.
>
> **It cannot grow.** One database instance for everything, services too tangled to deploy separately, no caching so the same expensive answer is computed again and again.

---

## Three decisions worth remembering

**Caching.** Redis for values you look up constantly. A [[cdn]] for images, video and static files. Query level caching for repeated reads, which is what DataLoader does in GraphQL by batching lookups that happen in one request.

**Observability.** You cannot fix what you cannot see. Datadog, Sentry and SumoLogic collect logs, errors and traces so you can follow one request across several services.

**Rate limiting and circuit breakers.** Two different jobs.

| Guard | Protects you from |
| --- | --- |
| **Rate limiting** | too many requests arriving |
| **Circuit breaker** | a dependency that has already failed. After enough failures it stops calling that service for a while, so one sick service does not drag the rest down |

> [!tip] Pair it with [[exponential-backoff]]
> Retries without backoff turn a brief failure into an outage you caused.
