# Hot Key

> [!tldr]
> One key, shard or partition takes so much of the traffic that the single machine holding it runs out of capacity while its neighbours sit almost idle.

Sharding assumes traffic follows keys evenly. Real traffic follows attention, and attention is never even. Adding machines does not help, because the problem is not total capacity, it is that one item can only live in one place.

> [!example]- Three shapes of the same failure
> | Situation | Why it concentrates | What you see |
> | --- | --- | --- |
> | A celebrity posts to 50 million followers | one `userId` key is read by everyone at once | one Redis node at 100 percent CPU, the rest at 10 |
> | A flash sale on one product | every checkout decrements the same inventory row | lock contention and timeouts on one row |
> | Sharding by `country` | 200 possible values, one of them holds most users | one shard 10 times the size of the others |

The fixes are the same three every time.

**Split the key.** Instead of one counter at `views:post123`, keep ten at `views:post123:0` through `:9`, write to a random one, and sum all ten on read. Ten keys hash to ten different nodes, so the write load spreads. This is called salting or bucketing, and it trades a cheap read for a spread out write.

**Cache it closer.** A value read a million times a second and changed rarely belongs in memory inside the application process, not behind a network hop. Even a one second local cache turns a million reads into one.

**Give it its own space.** If one tenant or one entity is genuinely enormous, stop trying to make it fit the general scheme and put it on a dedicated partition or node.

> [!tip] Pick shard keys by spread, not by meaning
> `country` and `status` feel like natural groupings, which is exactly why they get chosen and exactly why they fail. High [[cardinality]] keys such as `userId` and `orderId` spread; low cardinality keys concentrate.

**Shows up in:** [[caching-problems]], [[partitioning]], [[flash-sale-inventory]], [[sharding]].
