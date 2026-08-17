# Read Scaling, Stage by Stage

> [!tldr]
> A read heavy system evolves in a fixed order, and each optimisation creates the next bottleneck. Knowing the order matters more than knowing any single technique.

---

## The parts

| Note | Covers |
| --- | --- |
| [[caching-and-resilience]] | caching, replicas and the evolution toward resilience under concurrent load |
| [[query-optimization]] | expensive queries, query planning, denormalisation, [[cqrs|CQRS]], materialized views and observability |

---

## The evolution in one block

```text
DB overload            -> add cache
Cache bottlenecks      -> add hot key protection
DB read pressure stays -> add replicas
Traffic bursts collapse-> add resilience engineering
Queries expensive      -> denormalize
Read/write conflict    -> CQRS
Aggregations expensive -> materialized views
Pagination expensive   -> cursor pagination
Heap fetches expensive -> covering indexes
```

---

## The read heavy problem catalogue

It is worth recognising the shapes these problems come in.

**Read heavy social and feed systems.** Celebrity profile systems under viral traffic, infinite scroll feeds, personalised news feeds, trending post ranking, homepage recommendation retrieval, follower and following retrieval, activity feed and timeline reads, comment reading under heavy concurrency, notification read systems, real time trending hashtag discovery.

**Cache, [[cdn|CDN]] and [[hot-key|hot key]] systems.** Redis architecture for heavy read systems, layered CDN plus Redis plus DB reads, hot key resistant caching for viral content, cache invalidation strategy, distributed cache consistency with stale read handling.

**Database and query optimisation.** Cursor pagination for billion row datasets, CQRS read optimised architecture, denormalised read models, materialized view driven dashboards, join heavy reporting, `EXPLAIN ANALYZE` debugging, slow query optimisation, replica lag aware read routing.

**High concurrency and resilience.** Read heavy APIs surviving retry storms, graceful degradation during read overload, read heavy microservice fanout aggregation, distributed API aggregation gateways, surviving connection pool exhaustion.

**GraphQL, ORM and N+1.** GraphQL backends suffering N+1 amplification, ORM heavy backends generating hidden query explosions.
