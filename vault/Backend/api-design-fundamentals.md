# API Design Fundamentals

> [!tldr]
> Start with use cases and resources, then design endpoints with clear contracts, pagination, filtering, and sorting.

Part of [[api-design]].

---

## The design flow

> [!tip] Say this first
> I start from use cases, model resources, define clear contracts, and then design for scale, security and observability.

The order matters.

1. Understand use cases and consumers
2. Identify resources, the nouns
3. Design endpoints with REST semantics
4. Define request and response contracts
5. Handle pagination, filtering and sorting
6. Add auth, security and validation
7. Think about scale, performance and observability
8. Versioning and backward compatibility

Error handling within step 4 has its own checklist: race conditions, retry safety, idempotency state, idempotency keys, atomic multi step updates, partial failure of external services, background job duplication, and timeout or downstream failure. See [[idempotency]].

---

## Resources and endpoints

Resources are nouns: user, order, product, payment. Endpoints carry no verbs.

```text
POST   /orders
GET    /orders/{id}
GET    /users/{id}/orders
PATCH  /orders/{id}
DELETE /orders/{id}
```

> [!tip] The line
> URLs represent resources, HTTP methods represent actions.

---

## Pagination

APIs returning large lists can kill the database, memory and latency. Never return unbounded lists.

### Offset pagination, simple but not scalable

```text
GET /orders?limit=20&offset=40
```

It is slow for large offsets, and data becomes inconsistent if rows change underneath. Fine for small datasets.

### Cursor pagination, the preferred form

```text
GET /orders?limit=20&cursor=eyJpZCI6IjEyMyJ9
```

The cursor is the last seen ID or timestamp, which is faster and stable.

> [!tip] The line
> For large datasets I prefer cursor based pagination, because it is stable and performant.

**Why are cursors encoded?** Primarily to make the cursor opaque, so clients treat it as an uninterpreted token. Encoding also lets the server package multiple fields into a single value and evolve the cursor format over time. As a bonus, a URL safe encoding like Base64URL means the cursor travels safely in query parameters without worrying about reserved characters.

```text
Standard Base64 : ab+c/de=
Base64URL       : ab-c_de
```

The response shape:

```json
{
  "data": [],
  "nextCursor": "abc123"
}
```

---

## Filtering

Filtering reduces the dataset size at the database level.

```text
GET /orders?status=DELIVERED&userId=123
```

It reduces payload, reduces DB load and improves latency.

> [!tip] The line
> Filtering should always happen at the database, not in memory.

---

## Sorting

```text
GET /orders?sortBy=createdAt&order=desc
```

Allow only whitelisted fields. Never allow arbitrary fields, which is both a performance and a security risk.

> [!tip] The line
> I explicitly whitelist sortable fields to avoid performance and security issues.

**Where to sort.** Sort as close to the data as possible, unless the data is already in memory. If the data is already in your app, sort in memory. If it is still in the database, sort there. Never pull huge data just to sort it.

Sorting in the database costs disk I/O, possible temp tables, CPU contention and network latency. But databases can sort huge datasets, use indexes to avoid sorting altogether, apply `LIMIT` early for top-K optimisation, and avoid sending unnecessary rows over the network. That wins when the dataset is large, you only need part of the result, indexes can help, and you want scalability.
