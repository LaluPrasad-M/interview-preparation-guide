# Hot Key

> [!tldr]
> One key, shard or partition gets so much traffic that the single node holding it saturates while its neighbours sit idle.

Happens when a key goes viral, a shard key has low cardinality, or a partition key routes too much traffic to one place. A celebrity profile, a flash sale item and a `country` shard key all create the same failure shape.

The fixes repeat everywhere: salt or bucket the key to spread the load, cache the value aggressively, or give the entity its own dedicated partition.

**Shows up in:** [[caching-problems]], [[partitioning]], [[flash-sale-inventory]], [[sharding]].
