# Incident Categories

> [!tldr]
> Ten buckets that most production incidents fall into. State is the hardest one, because it is the hardest thing to scale, migrate and fix mid outage.

---

## The categories

**Database and storage.** State is the hardest component to scale, migrate and fix during an outage.

**Microservices and APIs.** Cascading failures, timeouts and network boundaries dictate overall system resilience.

**Asynchronous processing and message queues.** Complexities in event driven systems such as Kafka pipelines, ordering, and backpressure.

**Memory.** Heap exhaustion, memory leaks and garbage collection thrashing, especially critical in a single threaded runtime.

**CPU.** Event loop blocking, thread pool exhaustion, and compute bottlenecks.

**Infrastructure and cloud.** Cloud native failures, auto scaling thrashing, and IAM issues.

**Caching and performance.** Cache stampedes, penetration, and invalidation strategies.

**Rate limiting and traffic management.** Gateway protections, WAFs, and handling sudden traffic spikes.

**Authentication and security.** Token storms, identity provider outages, and secret rotation failures.

**Networking and DNS.** VPC routing, BGP leaks, and TLS certificate expirations.
