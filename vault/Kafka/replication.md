# Replication and Replication Factor

> [!tldr]
> Partitions decide how much work Kafka can process in parallel. Replication decides how many broker failures Kafka can survive without losing acknowledged messages.

---

## Why replication is still needed even with an outbox

**Outbox protects the application to Kafka boundary.** It guarantees that once the DB commit succeeds and the event is stored in the outbox, then even if Kafka is temporarily unavailable the event can be retried later.

**Replication protects Kafka itself.** It guarantees that once Kafka has acknowledged an event, then even if the broker crashes the event still exists on replicas.

> [!tip] The key interview line
> Outbox guarantees that events are not lost before reaching Kafka. Replication guarantees that events are not lost after Kafka acknowledges them.

See [[distributed-transactions]] for the outbox pattern itself.

---

## Choosing a replication factor

### RF = 1, leader only

Highest throughput, lowest storage, lowest network traffic. But a single broker failure can lose data, and there is no fault tolerance. Use for dev and test environments.

### RF = 2, one leader plus one replica

Tolerates one broker failure and has less storage overhead than RF 3. But if one broker is down no additional redundancy remains, which makes maintenance windows less safe. Use for cost sensitive production systems.

### RF = 3, one leader plus two replicas

Tolerates one broker failure safely, with a good balance of durability, availability and cost. This is the industry standard. The costs are 3 times the storage and more replication traffic. Use for most production Kafka clusters.

### RF greater than 3

Higher durability, but huge storage cost, more network replication and diminishing returns. Rarely needed, mostly for critical financial or audit systems.

---

## The trade off formula

Higher RF means higher durability, higher availability, higher storage cost, higher network traffic, and lower write throughput.

---

## Replication is not for parallelism

| Mechanism | Gives you |
| --- | --- |
| Partitions | scalability and parallelism |
| Replicas | fault tolerance and durability |

---

## Producer acks levels

| Setting | Meaning |
| --- | --- |
| `acks=0` | fire and forget |
| `acks=1` | leader only ack |
| `acks=all` | leader plus [[in-sync-replicas|ISR]], the strongest durability |

ISR, the in sync replicas, are the replicas acknowledged to be up to date with the leader.
