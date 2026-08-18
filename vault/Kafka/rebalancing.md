# Consumer Rebalancing

> [!tldr]
> Kafka does not route requests during rebalancing. It changes partition ownership among consumers, and during that change nobody processes anything.

---

## What rebalancing is

```text
Before:
P0, P1 -> Consumer A
P2, P3 -> Consumer B

Consumer B dies

After:
P0, P1 -> Consumer A
P2, P3 -> Consumer C
```

---

## Who detects consumer failure

Each consumer sends periodic heartbeats to the group coordinator.

```text
Consumer -> Heartbeat -> Group Coordinator
```

If heartbeats stop beyond `session.timeout.ms`, the consumer is considered dead and a rebalance is triggered.

---

## What the group coordinator is

The group coordinator is a special Kafka broker responsible for tracking consumers in a consumer group, receiving heartbeats, triggering rebalances, and managing partition assignments.

Think of it as the consumer group manager.

---

## The rebalance flow

```text
Consumer joins or dies
        |
Coordinator detects change
        |
Group enters REBALANCING state
        |
Partition assignment recalculated
        |
Consumers receive new assignments
        |
Consumers resume processing
```

**Triggers.** A consumer joins, a consumer leaves, a consumer crashes, or the partition count changes.

---

## Partition assignment strategies

The common assignors are `RangeAssignor`, `RoundRobinAssignor`, `StickyAssignor` and `CooperativeStickyAssignor`.

The most commonly discussed is `StickyAssignor`, whose goal is balanced load plus minimum partition movement.

---

## Eager rebalancing, the old way

When membership changes: stop all consumers, revoke all partitions, reassign everything, resume.

The problem is a large pause in consumption.

---

## Cooperative rebalancing, the modern way

`CooperativeStickyAssignor` only moves the partitions that need to move.

```text
A -> P0, P1
B -> P2, P3

Consumer C joins

A gives up P1
B gives up P3

Result:
A -> P0
B -> P2
C -> P1, P3
```

Less downtime, less partition movement, faster rebalance.

---

## How a new consumer resumes

Kafka stores committed offsets in the internal topic `__consumer_offsets`.

If partition P2's last committed offset is 1000, the new consumer that gets P2 reads offset 1000 and continues from there. No need to start from the beginning.

`__consumer_offsets` stores consumer group IDs, partition ownership metadata and committed offsets. Kafka uses Kafka itself to store offsets.

---

## Rebalance storms

A [[rebalance-storm|rebalance storm]] is continuous rebalancing causing repeated pauses in consumption.

**Common causes.** Frequent pod restarts, rolling deployments, consumer crashes, missed heartbeats, long processing times.

**Symptoms.** Lag spikes, throughput drops, frequent consumer join and leave logs.

**Monitor.** Rebalance count, consumer joins, consumer leaves.

### The four mitigations

**1. Tune the timeouts.** Give `session.timeout.ms` and `max.poll.interval.ms` room for your real processing time.

**2. Poll frequently.** Use smaller batches, process asynchronously, and avoid long blocking work inside the poll loop. See [[lag-and-dead-letter-queues]] for head of line blocking, which is the usual cause.

**3. Static membership.** Set `group.instance.id` so Kafka recognises the same consumer coming back after a restart, and skips the unnecessary rebalance. This is the one people forget, and it is the direct fix for rolling deployments.

**4. Cooperative rebalancing.** Use `CooperativeStickyAssignor` so only the affected partitions move.

> [!warning] The interview line
> During rebalancing, consumers stop processing. Excessive rebalancing can become a major source of lag.

---

## The one liner

> [!tip] Say this
> Kafka rebalancing is managed by the group coordinator. Consumers send heartbeats, membership changes trigger a rebalance, partitions are reassigned using an assignor strategy, and consumers resume from the last committed offsets stored in `__consumer_offsets`. Modern Kafka uses cooperative rebalancing to minimise partition movement and downtime.
