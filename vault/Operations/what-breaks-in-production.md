# What Breaks In Production

> [!tldr]
> Ten buckets that most production incidents fall into. State is the worst of them, because it is the hardest thing to scale, to migrate, and to fix while it is on fire.

---

## The ten buckets

| Bucket | What actually goes wrong |
| --- | --- |
| **Database and storage** | state is the hardest component to scale, migrate and fix during an outage |
| **Microservices and APIs** | cascading failures, timeouts, and network boundaries deciding how resilient the whole system is |
| **Async processing and queues** | event driven complexity: Kafka pipelines, ordering, [[backpressure]] |
| **Memory** | heap exhaustion, memory leaks, and garbage collection thrashing, which hurt most in a single threaded runtime |
| **CPU** | event loop blocking, thread pool exhaustion, compute bottlenecks |
| **Infrastructure and cloud** | cloud native failures, autoscaling thrashing, IAM problems |
| **Caching and performance** | stampedes, penetration, and invalidation going wrong |
| **Rate limiting and traffic** | gateway protections, WAFs, and sudden spikes |
| **Authentication and security** | token storms, identity provider outages, failed secret rotation |
| **Networking and DNS** | VPC routing, BGP leaks, TLS certificates expiring |

---

## Why state is the worst one

Everything else on that list can be restarted. A stuck pod gets killed, a hot cache gets flushed, a thrashing autoscaler gets pinned.

State does not work that way. A database that is slow under load is still the only copy of your data, so you cannot just turn it off and on again. You cannot add a second one halfway through an incident either, because the new one would start empty.

> [!tip] The one line to say out loud
> If a service is stateless you can just restart it. If it holds state, you have to keep it alive while you fix it.
