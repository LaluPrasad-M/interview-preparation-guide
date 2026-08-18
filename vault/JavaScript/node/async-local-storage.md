# AsyncLocalStorage

> [!tldr]
> A store that follows one request through every async hop, so a request id or trace id is available deep in the call stack without being passed as an argument to every function on the way down.

---

## The problem it solves

A log line written inside a database helper is useless if you cannot tell which request produced it.
The obvious fix is passing a context object into every function, which means changing every signature between the route handler and the place that logs.

`AsyncLocalStorage` keeps that context in the runtime instead of in your parameters.
You set it once per request, and any code running inside that request can read it, however deep it sits.

```js
const { AsyncLocalStorage } = require('node:async_hooks');

const context = new AsyncLocalStorage();

app.use((req, res, next) => {
  context.run({ requestId: req.headers['x-request-id'] ?? crypto.randomUUID() }, next);
});

function log(message) {
  const { requestId } = context.getStore() ?? {};
  console.log(JSON.stringify({ requestId, message }));
}
```

The `next` call and everything it triggers, including callbacks and awaited promises, run inside that store.

---

## What people keep in it

| Value | Used for |
| --- | --- |
| `requestId` | tying every log line of one request together |
| `traceId` | joining your logs to a distributed trace, see [[prometheus-grafana-loki]] |
| `userId` | audit logging without threading the user through every layer |
| `tenantId` | picking the right database or schema in a multi tenant service |

---

## The limitation worth saying out loud

> [!warning] The store stops at the process boundary
> `AsyncLocalStorage` is per Node process. It does not cross an HTTP call, a Kafka publish, or a queue job. For anything leaving the process, put the trace id in a header or the message envelope and have the receiving service read it back into its own store.

That is the whole reason tracing standards exist: the id has to be carried explicitly on the wire, and `AsyncLocalStorage` only saves you from carrying it explicitly inside one process.
