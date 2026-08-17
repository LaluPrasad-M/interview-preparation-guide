# Log Compaction

> [!tldr]
> Compaction retains the latest value for each message key and discards older values, so the log always holds a full snapshot of the final state of every key.

---

## What topic compaction is

Topic compaction is a mechanism that retains the latest value for each message key in a topic while discarding older values.

It guarantees that the latest value for each key is always retained within the log of that topic. That makes it ideal for restoring state after a system failure, or reloading caches after an application restart.

---

## The retention example

Take a topic that holds user email addresses. Every time a user updates their email, the topic receives a message keyed on the user ID. Over time, these messages are sent for user 123:

```text
123 => bill@microsoft.com
        .
        .
123 => bill@gatesfoundation.org
        .
        .
123 => bill@gmail.com
```

Log compaction provides a granular retention mechanism so at least the last update for each primary key is retained. Here, `bill@gmail.com` is retained.

This guarantees the log contains a full snapshot of the final value for every key, not just the keys that changed recently. Downstream consumers can restore their own state from this topic without needing a complete log of all changes.

---

## Where this matters

**Database change subscriptions.** You may have the same data set in multiple systems, for example a cache, a search cluster and Hadoop. For real time updates you only need the recent log, but to reload the cache or restore a failed search node you need the complete data set.

**Event sourcing.** Compaction does not enable event sourcing, but it does ensure you always know the latest state of each key, which matters when you build event sourcing on top of it.

**Journaling for high availability.** A process doing local computation can be made fault tolerant by logging out the changes it makes to local state, so another process can reload those changes and carry on if it fails. A concrete example is handling counts, aggregations and other group by style processing in a stream processor. Kafka Streams uses this feature for exactly that.
