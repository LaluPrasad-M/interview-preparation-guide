# Topic Design

> [!tldr]
> Do not start with "how many topics?". Start with "what business event streams exist?". Topics emerge from business boundaries.

---

## The questions to ask

Who owns the event? Who produces it? Who consumes it? What retention does it need? Are there compliance constraints? How will the schema evolve?

A topic is usually a business event stream, not a random collection of messages.

---

## Ordering is a partition problem

Kafka does not guarantee ordering at the topic level. It guarantees ordering only inside a partition.

So the actual design question is: what entity needs ordering? Examples are `order_id`, `account_id`, `product_id`, `driver_id`.

The entity whose state is changing usually becomes the partition key. See [[partitioning]] for the full framework.

---

## Schema registry

Most teams eventually regret not having one.

**The failure story.** A producer publishes `{ "leadId": "123", "clientId": "ABC" }`. Six months later a developer renames `clientId` to `customerId`. The consumer breaks, and it is a production incident.

**The solution.** The producer registers a schema, for example `LeadCreatedV1`. Before deployment, consumers validate compatibility automatically: is this backward compatible, forward compatible, or a breaking change?

> [!tip] The interview answer
> I would introduce a schema registry so Kafka events become versioned contracts rather than informal JSON payloads.

---

## Partition key is a business decision

Choosing a partition key is really choosing what should stay ordered.

```text
partition_key = order_id
```

guarantees that `ORDER_CREATED`, `PAYMENT_SUCCESS` and `ORDER_DELIVERED` stay ordered for that order.
