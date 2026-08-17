# Advanced API Design

> [!tldr]
> Senior-level API design: resource modelling, state machines, concurrency, idempotency, failure paths, and async patterns.

Part of [[api-design]].

---

## The non functional quick hits

Mention these briefly to signal real world experience: rate limiting, caching on GET requests, timeouts, retries, idempotency.

---

## The 30 second summary

> [!tip] Memorise this
> I design APIs by modelling resources, defining clear contracts, handling pagination, filtering and sorting at scale, securing endpoints with proper auth and validation, and adding observability so issues can be detected and debugged in production.

---

## The senior points, above the CRUD layer

The sheet above is the mechanics. These are the discussion points that actually separate levels.

### 1. Design starts with resource modelling

The weak approach is "let us create endpoints". The better one is asking what the business entities are, what state they own, and what actions are allowed. The resource model drives the API.

### 2. Business actions beat a generic PATCH

```text
Weak:   PATCH /rides/123  { "status": "completed" }
Better: POST /rides/123/complete
```

Accept ride, complete ride, cancel ride, refund payment are business operations, not arbitrary field updates. Many candidates miss this.

### 3. State machines matter more than endpoint names

```text
CREATED -> PENDING -> SUCCESS

REQUESTED -> ASSIGNED -> IN_PROGRESS -> COMPLETED
```

Interviewers often care more about which transitions are valid and which are not than about what you named the route.

### 4. Idempotency solves retries, not business rules

Many candidates think idempotency means no duplicates. It solves a narrower thing: the request succeeded, the response was lost, and the client retried.

The deeper question is what defines the same operation, and that is a business question, not a technical one.

### 5. Database constraints beat application logic

```text
Weak:   if (!exists()) insert()   // race condition
Better: UNIQUE(...), SELECT FOR UPDATE, or an atomic update
```

When correctness matters, database guarantees beat application guarantees. See [[api-failure-scenarios]].

### 6. Multi tenancy is mostly a data access problem

Most people focus on JWTs, the gateway and authentication. The real protection is `tenant_id` enforced in every data access path. The actual security boundary usually lives at the query layer.

### 7. Authentication is not authorization

Authentication asks who you are, authorization asks what you can do. Multi tenant systems fail on authorization mistakes far more often than authentication ones.

### 8. Context propagation

Authentication is useless unless the context propagates.

```text
JWT -> Gateway -> Service -> Database Query
```

Interviewers deliberately ask "okay, you authenticated the user, now what?" to test exactly this.

### 9. Large uploads should not flow through the backend

```text
Bad:  Client -> Backend -> S3
Good: Client -> Pre-signed URL -> S3
```

That saves bandwidth, latency and server cost.

### 10. Separate operational and search workloads

Do not force one database to do everything.

```text
Mongo -> Kafka -> Indexer -> Elasticsearch
```

See [[typeahead-search]].

### 11. Cursor pagination is about scalability, not convenience

`OFFSET 1000000` gets slower as data grows. A cursor keeps performance stable regardless of depth.

### 12. Concurrency is usually the real question

It showed up as double payment, ride acceptance and double refund. The endpoint is not the interesting part. The interviewer is asking what happens when two requests arrive together.

Whenever you see money, inventory, booking or assignment, start thinking race condition immediately.

### 13. Async work changes the API

Deleting a document, sending a notification, generating a report, indexing search data. These should not necessarily return `200 OK`. Often `202 Accepted` is more accurate, and saying so is a senior signal.

### 14. Distributed transactions are not the first answer

When Mongo, S3, Kafka and a search index are all involved, do not jump to 2PC. Interviewers usually prefer saga, outbox, retries, compensation and soft delete. See [[distributed-transactions]].

### 15. Failure paths matter more than happy paths

Most candidates explain how to create a payment, upload a file, or book a ride. Interviewers ask what happens on retry, on timeout, when two requests arrive together, when one system fails, when Kafka is down. Seniority shows in those answers.

---

## The mental model to carry in

```text
Resource
   |
State Machine
   |
Request / Response
   |
Authorization
   |
Concurrency
   |
Idempotency
   |
Failure Handling
   |
Scalability
```

Most candidates stop after request and response. Most senior discussions start there.
