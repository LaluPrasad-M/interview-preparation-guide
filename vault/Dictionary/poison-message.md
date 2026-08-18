# Poison Message

> [!tldr]
> A message that consistently fails processing no matter how many times it is retried, because the problem is the message itself, not a transient fault.

A malformed payload is the classic example: retrying it changes nothing, so it just fails again. Left alone it blocks everything behind it on that partition, since a consumer processes messages in order and cannot skip ahead.

The fix is schema validation to catch bad payloads before they even queue, plus routing anything that still fails past a retry limit to a dead letter queue so the partition can keep moving.

**Shows up in:** [[lag-and-dead-letter-queues]], [[notification-delivery]].
