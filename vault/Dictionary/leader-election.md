# Leader Election

> [!tldr]
> A group of identical nodes agrees that exactly one of them is in charge, so decisions get made in one place instead of every node having to agree on every decision.

You need it whenever a job must happen once rather than once per instance. Ten copies of a service each running the same nightly billing cron means ten invoices. One elected leader running it means one.

The mechanism scales with how much you care. A Redis key claimed with `SET job:nightly node-3 NX PX 30000` is enough for a scheduled task: the `NX` flag means only the first node to ask gets it, and the expiry means a crashed leader releases the lock by itself. Kafka runs a much heavier version per partition, where a controller elects a leader broker and re-elects one the moment a broker drops out.

| Approach | Good for | Weakness |
| --- | --- | --- |
| Lock in Redis with a TTL | cron jobs, one-at-a-time workers | a network pause can produce two leaders briefly |
| Raft or ZooKeeper style consensus | database and broker leadership | more moving parts, needs an odd number of voters |

> [!warning] Split brain is the failure to name
> If the old leader is only unreachable rather than dead, it may still be working while a new leader is elected, and now two nodes both believe they are in charge. The usual guard is a fencing token, a number that increases with each election, which downstream systems check so they can reject work from the stale leader.

Whatever the mechanism, the two requirements are the same: one node acts while the others stand by, and the group can notice a missing leader and replace it without a human.

**Shows up in:** [[redis-use-cases]], [[choosing-a-datastore]], [[consumer-groups-and-offsets]].
