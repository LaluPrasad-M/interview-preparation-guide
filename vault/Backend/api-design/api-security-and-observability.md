# API Security and Observability

> [!tldr]
> Secure APIs with HTTPS, authentication, authorization, input validation, and rate limiting. Observe with structured logs, metrics, and distributed traces.

Part of [[api-design]].

---

## Auth and security

**Authentication asks who you are.** JWT, OAuth2, or API keys for internal services, sent as `Authorization: Bearer <JWT>`.

**Authorization asks what you can do.** Role based access control and ownership checks. A user can only access their own orders, an admin can access all.

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
> It is not "never accept dangerous strings". It is to never interpret untrusted input as code or query syntax. Always treat it as data.

---

## NoSQL injection, which looks nothing like SQL injection

MongoDB queries are objects, not strings, so there is no quote to escape and no syntax error to notice.
The attacker sends an operator where you expected a value.

```js
db.users.findOne({
  email: req.body.email,
  password: req.body.password,
});
```

Now the login body arrives as:

```json
{ "email": { "$ne": null }, "password": { "$ne": null } }
```

The query becomes "any user whose email is not null and whose password is not null", which matches the first user in the collection.
That is a login bypass, with no error logged and nothing that looks wrong in the code.

Three defences, in the order they are worth adding:

| Defence | What it does |
| --- | --- |
| Check the type | `typeof email !== "string"` rejects the object before it reaches the driver, which stops most of these outright |
| Enforce a schema | a Mongoose schema with `strict: true` drops fields you did not declare, so stray operators never make it into the query |
| Coerce explicitly | wrapping with `String(req.body.email)` forces a primitive, whatever arrived |

> [!warning] Never put user input inside $where
> `$where: "this.email === '" + email + "'"` runs JavaScript inside the database. It is `eval` with your data attached, and no amount of escaping makes it safe.

| | SQL injection | MongoDB injection |
| --- | --- | --- |
| Root cause | string concatenation | an object where a value was expected |
| Typical payload | `' OR 1=1 --` | `{ "$ne": null }` |
| Main defence | parameterised queries | validate types, enforce a schema |
| How it shows up | often obvious, broken syntax or odd results | silent, the query runs and simply matches too much |

> [!tip] The one liner
> MongoDB injection happens when user controlled objects introduce query operators, so the fix is validating types and enforcing a schema rather than escaping strings.

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
