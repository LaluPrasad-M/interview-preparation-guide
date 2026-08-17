# What Breaks In Production

> [!tldr]
> Ten buckets that most production incidents fall into. State is the worst of them, because it is the hardest thing to scale, to migrate, and to fix while it is on fire.

---

## The ten buckets

| Bucket | What actually goes wrong |
| --- | --- |
| **Database and storage** | state is the hardest component to scale, migrate and fix during an outage |
| **Microservices and APIs** | cascading failures, timeouts, and network boundaries deciding how resilient the whole system is |
| **Async processing and queues** | event driven complexity: Kafka pipelines, ordering, backpressure |
| **Memory** | heap exhaustion, memory leaks, garbage collection thrashing, which bite hardest in a single threaded runtime |
| **CPU** | event loop blocking, thread pool exhaustion, compute bottlenecks |
| **Infrastructure and cloud** | cloud native failures, autoscaling thrashing, IAM problems |
| **Caching and performance** | stampedes, penetration, and invalidation going wrong |
| **Rate limiting and traffic** | gateway protections, WAFs, and sudden spikes |
| **Authentication and security** | token storms, identity provider outages, failed secret rotation |
| **Networking and DNS** | VPC routing, BGP leaks, TLS certificates expiring |

---

## Why state is the worst one

Everything else on that list can be restarted. A stuck pod gets killed, a hot cache gets flushed, a thrashing autoscaler gets pinned.

State cannot. A database that is slow under load is still the only copy of the data, so you cannot turn it off and on again, and you cannot scale it sideways in the middle of an incident.

> [!tip] The one line to say out loud
> Stateless things you restart. Stateful things you nurse.
