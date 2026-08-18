# In-Sync Replicas (ISR)

> [!tldr]
> The replicas of a Kafka partition that are caught up with the leader right now. Only these are allowed to take over if the leader dies, which makes the ISR the real measure of how safe your data is.

Replication factor tells you how many copies exist on paper. The ISR tells you how many are actually current. A replica that falls too far behind is removed from the set automatically, and it is added back once it catches up.

> [!example]- Replication factor 3, `min.insync.replicas` 2, `acks=all`
> | State | ISR | What happens to writes |
> | --- | --- | --- |
> | Healthy | leader plus 2 followers | leader waits for both followers, then acknowledges |
> | One broker down | leader plus 1 follower | still accepted, because 2 satisfies the minimum |
> | Two brokers down | leader only | producer gets an error, writes are refused |
>
> That last row is the setting doing its job. Kafka would rather refuse the write than accept it into a single copy that a second failure would erase.

The producer setting and the topic setting only mean something together.

| `acks` | Leader waits for | Data loss risk |
| --- | --- | --- |
| `0` | nothing, fire and forget | high, the write may never land |
| `1` | itself only | the leader crashing before replication loses the write |
| `all` | every replica currently in the ISR | none, as long as `min.insync.replicas` is above 1 |

> [!warning] A shrinking ISR is a warning on its own
> Nothing is broken yet, and that is what makes it easy to ignore. It means followers are lagging, usually from network latency or an overloaded broker, and your real durability is now thinner than the replication factor on the dashboard suggests.

`acks=all` with `min.insync.replicas` left at 1 is the trap: the leader waits for an ISR that might contain only itself, so you pay the latency of strong durability and get none of it.

**Shows up in:** [[replication]], [[internals]], [[lag-and-dead-letter-queues]].
