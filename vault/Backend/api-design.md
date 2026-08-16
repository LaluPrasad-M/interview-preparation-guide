# API Design

> [!tldr]
> What interviewers are really asking: does this person design APIs that will not break, will not leak data, and will not fall over at scale?

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

---

## Auth and security

**Authentication asks who are you.** JWT, OAuth2, or API keys for internal services, sent as `Authorization: Bearer <JWT>`.

**Authorization asks what can you do.** Role based access control and ownership checks. A user can only access their own orders, an admin can access all.

### The full security answer

"All communication happens over HTTPS to prevent eavesdropping. Authentication uses JWT bearer tokens in the Authorization header. The service validates the token and performs authorization using RBAC or permission based checks from the JWT claims. Every request is validated and sanitised to prevent SQL injection, NoSQL injection, XSS or command injection. Rate limiting prevents abuse and brute force. Sensitive information is not exposed in logs, and security headers and audit logging are enabled."

Each layer protects against a different class of problem. HTTPS protects data in transit. Authentication proves who the caller is. Authorization determines what they can do. Input validation ensures the data itself is safe. Rate limiting protects against abuse and denial of service.

---

## Why injection actually happens

The request body itself is never dangerous. It becomes dangerous only if your application later interprets that data as code or as part of a query.

Suppose the user sends:

```json
{ "email": "' OR 1=1 --" }
```

Receiving this JSON is harmless. Storing it is harmless. The problem happens when a developer builds a query like this:

```js
const query =
  "SELECT * FROM users WHERE email = '" + req.body.email + "'";
```

The final query becomes:

```sql
SELECT * FROM users
WHERE email = '' OR 1=1 --'
```

`OR 1=1` is always true and `--` comments out the remaining quote, so the database returns every user. The attack did not happen because of the request body. It happened because the application treated user input as part of SQL syntax.

Write it this way instead:

```js
db.query(
  "SELECT * FROM users WHERE email = ?",
  [req.body.email]
);
```

Now the database knows this is data, not SQL. Even if the email is `' OR 1=1 --`, it searches for a literal email containing those characters. That is why parameterised queries prevent SQL injection.

The same idea applies to HTML. Someone submits:

```json
{ "comment": "<script>alert('Hacked')</script>" }
```

Receiving and storing it is fine. The danger comes when your site renders comments directly, because the browser executes the script and every visitor runs it. That is cross site scripting. If you escape the HTML instead, the browser displays it as text.

The pattern repeats everywhere. User input reaching an SQL query gives SQL injection, an HTML page gives XSS, a shell command gives command injection, a MongoDB query object gives NoSQL injection.

> [!tip] The real principle
> It is not "never accept dangerous strings". It is never interpret untrusted input as code or query syntax. Always treat it as data.

See [[cross-site-scripting]] for the XSS defences in detail.

---

## Validation

Validation prevents bad data, crashes and security bugs. Validate required fields, data types, range checks and enum values.

```json
{ "quantity": -5 }
```

> [!tip] The line
> I validate inputs at the API boundary before business logic.

```json
{
  "errorCode": "INVALID_INPUT",
  "message": "quantity must be >= 1"
}
```

---

## Error handling

| Code | Meaning |
| --- | --- |
| 400 | bad request |
| 401 | unauthorized |
| 403 | forbidden |
| 404 | not found |
| 409 | conflict |
| 500 | server error |

Keep the error format consistent:

```json
{
  "errorCode": "ORDER_NOT_FOUND",
  "message": "Order does not exist"
}
```

> [!tip] The line
> I keep error responses consistent so clients can handle them reliably.

---

## Observability

**Logs** carry request ID, user ID and errors. Logs answer what happened.

**Metrics** carry request count, latency and error rate. Metrics answer how often and how bad.

**Traces** carry the request flow across services. Tracing helps debug distributed systems.

> [!tip] The power line
> I add correlation IDs so a single request can be traced across services.

---

## Versioning

Clients depend on APIs, so breaking changes mean production outages.

```text
/v1/orders
/v2/orders
```

Or by header: `Accept: application/vnd.company.v1+json`.

> [!tip] The line
> I avoid breaking changes and version APIs explicitly.

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

Delete document, send notification, generate report, index search data. These should not necessarily return `200 OK`. Often `202 Accepted` is more accurate, and saying so is a senior signal.

### 14. Distributed transactions are not the first answer

When Mongo, S3, Kafka and a search index are all involved, do not jump to 2PC. Interviewers usually prefer saga, outbox, retries, compensation and soft delete. See [[distributed-transactions]].

### 15. Failure paths matter more than happy paths

Most candidates explain create payment, upload file, book ride. Interviewers ask what happens on retry, on timeout, when two requests arrive together, when one system fails, when Kafka is down. Seniority shows in those answers.

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
