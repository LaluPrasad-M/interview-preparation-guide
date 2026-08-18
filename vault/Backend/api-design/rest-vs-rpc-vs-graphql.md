# REST vs RPC vs GraphQL

> [!tldr]
> Three different answers to "how should a client talk to a service": REST models resources, RPC models actions, GraphQL lets the client pick exactly the fields it wants back.

---

## REST

Resource-centric. URLs name nouns, HTTP verbs name the action.

```text
GET    /orders/123
POST   /orders
PATCH  /orders/123
DELETE /orders/123
```

**Strengths.** Cacheable by default through HTTP semantics, a huge existing tooling ecosystem, and a shape most engineers already know without documentation.

**Weaknesses.** Over-fetching, a mobile client gets the full order object when it only needed the status. Under-fetching, related data often needs a second round trip. Awkward for actions that are not naturally a resource, for example "refund" does not map cleanly onto a noun and a verb.

**When to use.** Public APIs, CRUD-shaped domains, anywhere caching at the HTTP layer is valuable.

---

## RPC

Action-centric. The client calls a named function, not a resource.

```text
POST /refundOrder
POST /calculateShipping
```

gRPC is the common modern form, adding a strict schema (protobuf), code generation for clients in multiple languages, and binary serialization instead of JSON.

**Strengths.** Natural fit for actions and commands rather than CRUD. gRPC specifically is fast, low-latency, and gives you generated, type-safe clients across languages, which is why internal service-to-service calls reach for it.

**Weaknesses.** Not cacheable the way REST is, since there is no resource URL for a cache to key on. Less browsable and discoverable than REST, no field on a URL to inspect. gRPC's binary format is not human-readable, so debugging needs the right tooling.

**When to use.** Internal service-to-service calls where latency matters and both ends are services you control, or explicitly action-shaped operations that never fit REST's noun model.

---

## GraphQL

Client-centric. One endpoint, and the client specifies exactly which fields it wants.

```graphql
query {
  order(id: "123") {
    status
    total
  }
}
```

**Strengths.** Solves REST's over-fetching and under-fetching directly, since the client asks for precisely what it needs, in one round trip, across related objects.

**Weaknesses.** Every query is a POST to the same endpoint, so HTTP-level caching does not apply the way it does for REST's per-resource URLs. The N+1 problem moves into the resolver layer, solved with batching tools like DataLoader. Query complexity itself becomes an attack surface, a client can request a deeply nested query that is expensive to resolve, which needs its own rate limiting or query cost analysis.

**When to use.** Clients with varied data needs from the same backend, for example a mobile app and a web app wanting different subsets of the same object graph.

---

## The one table to recall under pressure

| | REST | RPC / gRPC | GraphQL |
| --- | --- | --- | --- |
| Models | resources | actions | a queryable graph |
| Over/under-fetching | both happen | not the concern it solves | solved by design |
| Caching | HTTP caching works naturally | not naturally cacheable | not naturally cacheable |
| Best fit | public CRUD APIs | internal service-to-service | varied clients, same backend |

> [!tip] Interview gold line
> REST models resources, RPC models actions, GraphQL lets the client decide the shape of the response. Pick based on who is over-fetching and who controls both ends of the call, not by habit.
