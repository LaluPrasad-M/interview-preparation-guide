# Rebalance Storm

> [!tldr]
> Consumers keep rebalancing back to back, so the group spends more time reassigning partitions than actually processing them.

A single rebalance is normal and cheap. A storm is what happens when something keeps triggering new ones before the last one settles: frequent pod restarts, rolling deployments, consumer crashes, or missed heartbeats from a consumer stuck on a long processing task.

Every rebalance pauses consumption for the whole group while partitions get reassigned, so a storm looks like intermittent lag spikes with no single obvious cause.

**Shows up in:** [[rebalancing]].
