# Rebalance Storm

> [!tldr]
> A Kafka consumer group keeps rebalancing over and over, so it spends more time reassigning partitions than processing messages.

One rebalance is normal. It happens whenever a consumer joins or leaves, and partitions get redistributed across whoever is left. The problem is that consumption stops for the whole group while that happens, so anything that triggers rebalances repeatedly turns a routine pause into continuous downtime.

| Trigger | Why it repeats |
| --- | --- |
| Rolling deployment | every pod replaced is a leave plus a join |
| Pods restarting, often from an out of memory kill | each restart triggers two more rebalances |
| Processing that outlasts `max.poll.interval.ms` | the broker decides the consumer is dead and evicts it, then it comes back |
| Missed heartbeats from a blocked thread | same eviction, no crash to point at |

The third row is the sneaky one. Nothing has crashed and the logs look clean, but a consumer that takes 6 minutes to handle a batch against a 5 minute poll interval gets kicked out mid batch, rejoins, gets the partition back, and does it again forever.

The symptom is intermittent lag spikes with no obvious cause, because the cause is the gaps rather than any slow message.

> [!tip] Three settings cover most of it
> Fetch smaller batches with `max.poll.records` so a batch always finishes inside the poll interval. Give consumers a stable `group.instance.id` so a restarting pod rejoins as itself instead of as a new member. Use the cooperative sticky assignor so a rebalance moves only the partitions that need moving rather than stopping the whole group.

**Shows up in:** [[rebalancing]], [[websocket-bridge]], [[where-to-look-by-component]].
