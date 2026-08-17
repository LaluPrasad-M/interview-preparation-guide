# Last Write Wins (LWW)

> [!tldr]
> When two regions write the same record at once, the write with the later server timestamp silently overwrites the other.

Native to databases like DynamoDB and Cassandra, and simple to reason about, but it depends entirely on clock accuracy. If one region's clock drifts ahead, its writes incorrectly beat writes that actually happened later elsewhere.

Losing the losing write is the accepted trade off. Avoiding that loss means CRDTs or vector clocks instead, which cost real engineering complexity.

**Shows up in:** [[multi-region-cart]], [[sharding-and-scale]], [[nfr-decision-table]].
