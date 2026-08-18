# Leader Election

> [!tldr]
> A group of nodes agrees on exactly one of themselves to coordinate, so writes or scheduling do not need every node to agree on every decision.

A Redis lock (`SET key value NX PX`) is enough for simple cases like making sure only one instance runs a scheduled job. Kafka runs a heavier version of this per partition, electing a leader broker and re-electing one whenever a broker crashes.

The point either way is the same: exactly one node acts, everyone else defers, and the system has a way to notice when the leader is gone and pick a new one.

**Shows up in:** [[redis-use-cases]], [[choosing-a-datastore]], [[consumer-groups-and-offsets]].
