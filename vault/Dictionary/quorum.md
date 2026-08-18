# Quorum

> [!tldr]
> A read or write counts as done once enough replicas have answered, not all of them. That way one slow or dead node cannot stall the whole system.

Waiting for every replica gives you the strongest guarantee and the worst availability, since the slowest machine sets your latency and any failure blocks writes. A quorum is the middle setting: a majority is enough.

Three numbers matter. N is the number of replicas, W is how many must acknowledge a write, and R is how many must answer a read.

| N | W | R | Result |
| --- | --- | --- | --- |
| 3 | 2 | 2 | R plus W is 4, above 3, so a read always sees the latest write and one node can fail |
| 3 | 3 | 1 | writes are slow and fragile, reads are instant |
| 3 | 1 | 1 | fastest, but a read can easily miss the newest write |

The rule is `R + W > N`. If the write went to 2 of 3 and the read asks 2 of 3, the two sets must overlap in at least one node, and that node has the current value. Overlap is the whole mechanism.

> [!tip] Same replicas, different guarantee per call
> Because R and W are per operation in systems like DynamoDB and Cassandra, one endpoint can ask for a strong read while another accepts a stale one. Consistency becomes a choice you make per query rather than a property of the database.

**Shows up in:** [[sharding-and-scale]], [[scaling-ladders]].
