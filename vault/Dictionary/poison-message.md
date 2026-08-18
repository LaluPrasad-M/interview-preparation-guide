# Poison Message

> [!tldr]
> A message that fails every single time it is processed, because the problem is the message itself and not a passing glitch. Retrying it forever changes nothing except how long everything behind it waits.

The usual cause is a payload the consumer cannot handle: a missing field, a string where a number belongs, a reference to a row that no longer exists. A transient failure gets better on its own; this one does not.

The damage is head of line blocking. A Kafka consumer reads a partition in order and cannot skip ahead, so message 500 failing forever means messages 501 onwards never get processed, even though they are all perfectly fine. Lag on that partition grows without any of the usual causes being present.

| Failure | Retry helps | Right response |
| --- | --- | --- |
| Database briefly unreachable | yes | retry with [[exponential-backoff]] |
| Downstream returned 503 | yes | retry, then back off |
| Payload is malformed | never | stop retrying, move it aside |
| Referenced record was deleted | never | move it aside, investigate separately |

Two fixes work together. Validate against a schema at the producer, so bad payloads never enter the topic in the first place. Then cap retries, and route anything still failing into a Dead Letter Queue (DLQ), which is a separate topic for messages that could not be processed. The partition keeps moving, and the failures sit somewhere you can inspect and replay after fixing the cause.

> [!warning] A dead letter queue nobody watches is a data loss queue
> Moving the message aside only helps if something alerts on it. Otherwise you have swapped a visible stuck consumer for an invisible pile of dropped work.

**Shows up in:** [[lag-and-dead-letter-queues]], [[notification-delivery]].
