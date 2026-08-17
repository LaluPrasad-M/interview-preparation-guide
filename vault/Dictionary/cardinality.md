# Cardinality

> [!tldr]
> How many distinct values a column or key can take. High cardinality means mostly unique values, low cardinality means the same few values repeated everywhere.

A good shard key or partition key needs high cardinality, like `userId` or `orderId`, so traffic spreads evenly. A low cardinality key like `status` or `country` sends most traffic to the same few shards.

The query planner also estimates cardinality to pick a join strategy, and a bad estimate, ten rows expected against ten million actual, is enough to wreck the whole plan.

**Shows up in:** [[sharding]], [[partitioning]], [[query-optimization]].
