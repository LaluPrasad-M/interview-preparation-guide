# req and res Reference

> [!tldr]
> `req` is a readable stream, `res` is a writable stream. Every method below follows from that one fact.

---

## The request object

| Type | Name | Purpose | Use case |
| --- | --- | --- | --- |
| Event | `data` | a chunk arrived | file uploads, streaming |
| Event | `end` | all request data received | finalise parsing |
| Event | `close` | connection terminated | cleanup, aborted uploads |
| Event | `error` | stream failure | malformed stream, network issue |
| Method | `pipe()` | forward the request stream | `req.pipe(fs.createWriteStream())` |
| Method | `pause()` | pause the flow | backpressure handling |
| Method | `resume()` | resume the flow | controlled streaming |
| Method | `destroy()` | terminate the stream | rejecting an invalid upload |
| Property | `req.method` | the HTTP method | routing, logging |
| Property | `req.url` | the requested URL | routing, logging |
| Property | `req.headers` | incoming headers | `req.headers.authorization` |
| Property | `req.body` | the parsed body | needs `express.json()` |
| Property | `req.params` | route params | `/users/:id` |
| Property | `req.query` | query params | `?page=1` |

---

## The response object

| Type | Name | Purpose | Use case |
| --- | --- | --- | --- |
| Event | `finish` | response fully sent | the best hook for latency logging |
| Event | `close` | connection terminated early | detecting an aborted response |
| Event | `error` | response stream failure | diagnostics |
| Method | `write()` | send a chunk | `res.write('chunk')` |
| Method | `end()` | finish the response | nothing can be written after this |
| Method | `json()` | send JSON | stringifies and ends the response |
| Method | `send()` | generic response | text, object or buffer, an Express helper |
| Method | `status()` | set the status code | `res.status(404)` |
| Method | `setHeader()` | set a header | native Node method |
| Method | `redirect()` | redirect the client | auth and login flows |
| Method | `download()` | file download | an Express helper |
| Method | `sendFile()` | send a static file | absolute path preferred |
| Property | `res.headersSent` | have headers gone out? | prevents a duplicate response |

---

## The lifecycle

```text
req:  data -> data -> end     incoming body lifecycle
res:  write() -> end()        outgoing response lifecycle

finish : the response completed successfully
close  : the connection or socket closed
```

---

## Response methods in detail

**Core.** `res.write(chunk)` writes body without finishing. `res.end([data])` ends the response, optionally writing final data. `res.setHeader(name, value)`, `res.getHeader(name)`, `res.getHeaders()` and `res.removeHeader(name)` manage headers.

**Status.** `res.statusCode = 201` is a property, not a function. `res.statusMessage` sets custom status text, rarely used. `res.writeHead(status, headers)` sets both at once, but is less flexible than `setHeader` in real apps.

```js
res.writeHead(200, {
  'Content-Type': 'text/plain'
});
```

**Streaming and flow control.** `res.flushHeaders()` sends headers immediately, which is what streaming and server sent events need. See [[websockets-and-sse]].

```js
res.setTimeout(5000, () => {
  res.end('Timeout');
});
```

**Connection.** `res.socket` exposes the underlying socket, for example `res.socket.remoteAddress`.

```js
if (!res.headersSent) {
  res.setHeader('X-Test', 'true');
}
```

That guard matters, because setting a header after headers are sent throws at runtime.

**Advanced.** `res.writeContinue()` sends `100 Continue`, used with large uploads. `res.cork()` and `res.uncork()` buffer writes temporarily for performance.

```js
res.cork();
res.write('A');
res.write('B');
res.uncork();
```

> [!tip] The mental model
> `res` is a writable stream. Headers must be set before the body, `res.end()` finalises everything, and once `headersSent` is true headers cannot change.

> [!tip] The one liner
> `res` is a writable HTTP stream that controls status, headers and body. `write()` streams data, `setHeader()` manages metadata, and `end()` finalises the response.

---

## `end` against `close`

**`req.on('end')`** fires when the request body has been fully received. All chunks arrived, the request completed normally, and it is safe to process the body. It does not fire if the client disconnects early.

**`req.on('close')`** fires when the underlying connection closes. It may fire before `end`, the body may be incomplete, and it indicates an aborted request. It is not safe to process data here.

### The execution order

```text
Normal request:      data -> data -> end -> close
Client aborts:       data -> close        (end never fires)
```

| Aspect | `end` | `close` |
| --- | --- | --- |
| Fired when | the request is fully read | the connection closed |
| All data received | yes | maybe |
| Safe to process the body | yes | no |
| Fires on client abort | no | yes |
| Typical use | body handling | cleanup and logging |

### The common mistake

```js
req.on('close', () => {
  // Wrong: the data may be partial
  process(data);
});
```

### The correct pattern

```js
req.on('end', () => {
  process(data);
});

req.on('close', () => {
  if (!res.writableEnded) {
    console.log('Request aborted by client');
  }
});
```

> [!tip] The one liner
> `end` means the request finished successfully, `close` means the connection ended, possibly before completion. Use `end` for processing data and `close` for cleanup.
