# Command Query Responsibility Segregation (CQRS)

> [!tldr]
> The write model and the read model are two different things, kept in sync asynchronously, instead of one schema trying to serve both well.

Writes want normalisation and transactional correctness. Reads want denormalised, precomputed shapes that are fast to query. Once those pull in different directions hard enough, the system splits: writes go to the primary database, and a projection, kept current via Kafka or CDC, serves reads.

The cost is real: projection lag, eventual consistency, and rebuilding a projection from scratch if it drifts. It is a fix for a specific scaling pain, not a default architecture.

**Shows up in:** [[query-optimization]], [[write-scaling]], [[geospatial-discovery]].
