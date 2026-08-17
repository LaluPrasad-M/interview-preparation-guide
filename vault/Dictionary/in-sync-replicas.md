# In-Sync Replicas (ISR)

> [!tldr]
> The set of replicas that are caught up with the partition leader right now, the only ones eligible to be promoted if the leader dies.

A replica falling behind on lag drops out of the ISR automatically; it rejoins once it catches back up. `acks=all` means the leader waits for every replica currently in the ISR to acknowledge, not every replica that technically exists.

A shrinking ISR is a warning sign on its own: it means replicas are falling behind, usually from network latency or an overloaded broker, and durability is thinner than the replication factor suggests.

**Shows up in:** [[replication]], [[internals]], [[lag-and-dead-letter-queues]].
