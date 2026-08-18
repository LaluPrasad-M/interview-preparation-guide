# Command Query Responsibility Segregation (CQRS)

> [!tldr]
> Stop making one data model serve both writing and reading. Keep a write model shaped for correctness, keep a separate read model shaped for the queries you actually run, and sync the second from the first in the background.

A command changes data and a query reads it, and the two want opposite things. Writes want each fact stored once so nothing can contradict itself. Reads want the answer precomputed so no joining is needed at request time.

| | Write model | Read model |
| --- | --- | --- |
| Shape | normalised, one fact in one place | denormalised, one document per screen |
| Optimised for | correct transactions | a single fast lookup |
| Lives in | the primary database | a projection, often Elasticsearch, Redis or a wide table |
| Consistency | immediate | eventually consistent, a moment behind |

> [!example]- An order history page
> The write side keeps `orders`, `order_items`, `products`, `users` and `addresses`, each normalised, because that is what makes a checkout transaction safe.
> The read side keeps one document per order with the customer name, the item names and the delivery address already baked in, so the page is one lookup by `orderId` instead of a five table join.
> A change on the write side flows across through Change Data Capture (CDC) or a Kafka topic, and the projection updates itself.

> [!warning] You are choosing to serve stale data
> The projection lags, usually by milliseconds and occasionally by minutes when it falls behind. A user who edits their address and immediately reloads may see the old one, so the read model needs a rebuild path and the product needs to tolerate the gap.

This is a fix for one specific pain, which is a read pattern the write schema cannot serve without heavy joins at high volume. Reaching for it before that pain exists buys you two models to keep in sync and nothing else.

**Shows up in:** [[query-optimization]], [[write-scaling]], [[geospatial-discovery]].
