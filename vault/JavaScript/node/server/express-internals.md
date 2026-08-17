# Express Internals and Streaming Bodies

> [!tldr]
> Express is Node's HTTP server plus a router plus a middleware engine. Once you see that, the body stream rule follows: it can only be consumed once.

---

## What Express actually is

> [!tip] The one line definition
> Express is a thin abstraction over Node's HTTP server that provides a middleware driven request pipeline, method based routing, and enhanced request and response objects, executed sequentially in registration order.

It hides `http.createServer`, manual routing and manual middleware chaining. Internally it still uses the request and response streams, a middleware stack, and recursive execution. See [[middleware-recursion]] for why that execution is recursive.

---

## When to stream a request body

Stream when the payload is large. Stream when you do not want it fully in memory. Stream when you want **backpressure** or progressive processing.

> [!warning] The rule that catches everyone
> If you use `req.on('data')`, you must not use `express.json()` on that route. The body stream can be consumed only once.

---

## Reading a large upload chunk by chunk

```js
const express = require('express');
const app = express();

app.post('/upload-log', (req, res) => {
  let size = 0;

  req.on('data', chunk => {
    size += chunk.length;
    console.log(`Received ${chunk.length} bytes`);
  });

  req.on('end', () => {
    res.json({
      message: 'Upload complete',
      totalBytes: size
    });
  });

  req.on('error', err => {
    res.status(400).json({ error: 'Stream error' });
  });
});

app.listen(3000);
```

Nothing buffers the whole file, processing happens chunk by chunk, and it scales to gigabyte uploads.

---

## Streaming straight to disk

The common case for video, CSV or backup ingestion.

```js
const fs = require('fs');

app.post('/upload-file', (req, res) => {
  const writeStream = fs.createWriteStream('./large-file.bin');

  req.pipe(writeStream);

  writeStream.on('finish', () => {
    res.json({ message: 'File saved' });
  });

  writeStream.on('error', () => {
    res.status(500).json({ error: 'Write failed' });
  });
});
```

Constant memory usage, OS level backpressure, fast and safe.

---

## Limiting the payload size

```js
app.post('/upload-safe', (req, res) => {
  let bytes = 0;
  const MAX = 10 * 1024 * 1024; // 10MB

  req.on('data', chunk => {
    bytes += chunk.length;

    if (bytes > MAX) {
      res.status(413).json({ error: 'Payload too large' });
      req.destroy();
    }
  });

  req.on('end', () => {
    res.json({ message: 'Upload ok' });
  });
});
```

Note the `413`, which is the correct code here. See [[http-status-codes]].

---

## Streaming JSON lines

For a huge stream of objects processed independently. The carry buffer is the detail worth remembering: the last element after a split may be a partial line.

```js
app.post('/stream-json', (req, res) => {
  let buffer = '';

  req.on('data', chunk => {
    buffer += chunk.toString();

    let lines = buffer.split('\n');
    buffer = lines.pop();

    for (const line of lines) {
      const obj = JSON.parse(line);
      console.log(obj);
    }
  });

  req.on('end', () => {
    res.json({ message: 'Processed JSON stream' });
  });
});
```

---

## What not to do

```js
app.use(express.json());

app.post('/upload', (req, res) => {
  req.on('data', () => {}); // wrong
});
```

`express.json()` already consumed the stream, so the events never fire.

---

## The decision table

| Scenario | Use |
| --- | --- |
| Small JSON, under 100 KB | `express.json()` |
| File upload | `req.pipe()` |
| Gigabyte sized data | manual streaming |
| Webhooks needing the raw body | `express.raw()` |
| CSV or logs | streaming |

The raw body row matters for signature verification. See [[webhook-signatures]].

---

## `end` against `close`

Two events that look interchangeable and are not.

| Flow | Event order |
| --- | --- |
| Normal request | `data`, `data`, `end`, `close` |
| Client aborts | `data`, `close`, and `end` never fires |

So if your cleanup lives in `end`, an aborted upload leaks. Put completion logic in `end` and cleanup in `close`.
