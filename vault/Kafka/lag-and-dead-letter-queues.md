# Consumer Lag, Poison Messages and DLQs

> [!tldr]
> Lag is usually a symptom. The first question is always whether offsets are moving.

---

## The lag investigation framework

The interview question is simply "Kafka lag is increasing". First determine: are offsets moving?

### Case 1, offsets are not moving

**Possible causes.** A poison message, a consumer crash, a consumer stuck or hung, a database deadlock, an external dependency timeout, or an infinite retry loop.

**Investigation.** Check the last committed offset, consumer logs, retries, and downstream dependencies.

### Case 2, offsets are moving

The producer rate exceeds the consumer rate.

**Investigate.** Consumer throughput, producer throughput, P95 and P99 processing latency, database latency, external API latency, event loop lag, GC pressure, CPU utilisation, memory utilisation, [[hot-key|hot partitions]].

> [!tip] The interview line
> First determine whether the consumer is making progress. If offsets are not moving, investigate blocked processing. If offsets are moving but lag is still growing, investigate throughput bottlenecks.

---

## Poison messages

A poison message is one that consistently fails processing, for example:

```json
{
  "customerId": null
}
```

Because ordering is preserved within a partition:

```text
Offset 100 -> Poison Message
Offset 101 -> Good Message
Offset 102 -> Good Message
```

101 and 102 are blocked until 100 is resolved.

> [!warning] The interview line
> A single poison message can block an entire partition.

---

## Dead letter queues

The purpose is to prevent poison messages from blocking partition progress forever.

```text
Main Topic
    |
Retry Topic (1m)
    |
Retry Topic (5m)
    |
Retry Topic (15m)
    |
DLQ
```

After moving a message to the DLQ, commit the original offset and continue processing.

> [!tip] The interview line
> A DLQ improves throughput by isolating permanently failing messages.

DLQs are not built into Kafka. They are implemented as separate topics.

---

## Metrics to monitor

**Kafka metrics.** Consumer lag, producer throughput, consumer throughput, rebalance count, partition distribution, [[in-sync-replicas|ISR]] shrink events.

**Application metrics.** P95 and P99 processing latency, event loop lag, database latency, API latency, CPU, memory, GC time.

> [!tip] The interview line
> Lag is usually a symptom. The root cause is often visible through latency, throughput, partition distribution, or downstream dependency metrics.

---

## Head of line blocking

**The question.** A topic has 10 partitions and 10 consumers. One message takes 30 minutes to process while the others take 2 seconds. What happens?

**The answer in one sentence.** Kafka processes messages sequentially within a partition. A slow message blocks the ones behind it because of the ordering guarantee, which causes head of line blocking and growing consumer lag.

### Why it happens

One partition is processed by only one consumer at a time, so partitions are the parallelism limit. Within a partition, order is guaranteed, so message B cannot be processed before message A.

```text
Partition 3

Message A (slow, 30 minutes)
Message B
Message C
Message D

Processing must follow A -> B -> C -> D
```

Everything behind A waits. Latency and lag both climb for that partition.

### The rebalancing risk on top

If processing exceeds `max.poll.interval.ms`, Kafka assumes the consumer failed and triggers a rebalance. So a slow message can also cause a spurious rebalance. See [[rebalancing]].

### The four fixes

**1. Increase partitions.** More partitions means more parallelism, so a slow message affects a smaller share of total messages. Note the caveat in [[partitioning]] about changing the partition count.

**2. Offload heavy processing.** Keep the consumer lightweight.

```text
Kafka -> Consumer -> Job Queue -> Worker Pool
```

The consumer acknowledges quickly and workers handle the heavy computation.

**3. Delegate to worker threads or services.** The consumer reads the message and hands the work off, but commits the offset only after processing completes.

**4. Separate topics.** Split `fast-processing-topic` from `slow-processing-topic`, so slow jobs never block fast ones.

> [!tip] The key insight
> Kafka parallelism depends on the number of partitions, not the number of consumers. With 10 partitions and 50 consumers, only 10 are active.

> [!warning] Say it correctly
> Kafka concurrency is partition based, not thread based. So the right phrasing is "the partition gets blocked", not "the thread gets blocked".

---

## Hot partition lag

Symptoms are one partition holding most of the lag, one consumer overloaded, and the others mostly idle. Adding more consumers does not help, because one partition maps to one consumer within a group. See [[partitioning]] for the mitigations.
