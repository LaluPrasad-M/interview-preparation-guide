# Cardinality

> [!tldr]
> How many different values a column or key actually holds. High cardinality means nearly every row is unique, low cardinality means the same handful of values repeat forever.

> [!example]- The same 10 million rows, five different columns
>
> | Column | Distinct values | Cardinality |
> | --- | --- | --- |
> | `orderId` | 10,000,000 | very high, one per row |
> | `email` | around 9,900,000 | high |
> | `city` | around 500 | medium |
> | `country` | around 200 | low |
> | `isActive` | 2 | very low |

It decides two separate things, and the same word gets used for both.

**As a shard or partition key.** High cardinality spreads traffic, low cardinality concentrates it. Sharding 10 million orders by `orderId` fills every shard evenly. Sharding by `country` puts 60 percent of an Indian company's traffic on one shard while the others idle, which is a [[hot-key]] by another name.

**As an index hint.** An index on `email` narrows a lookup from 10 million rows to one, so the database will happily use it. An index on `isActive` narrows it to 5 million rows, which is slower than just scanning the table, so the planner ignores the index you built.

The query planner also guesses cardinality when it picks a join strategy, and a bad guess is enough to wreck an otherwise fine query. Expecting 10 rows and meeting 10 million turns a nested loop that should have been a hash join into a query that never returns.

**Shows up in:** [[sharding]], [[partitioning]], [[indexing]], [[query-optimization]], [[schema-design-questions]], [[caching-problems]], [[study-roadmap]].
