---
tags: [revise]
owner: lalu
---

# Node Event Loop

## Idea

One thread runs your JS. libuv runs a loop of phases; each phase drains its own
callback queue. Anything blocking that thread blocks everything — that is the
whole interview answer, the phases are the detail.

## Phases, in order

1. **timers** — expired `setTimeout` / `setInterval`
2. **pending callbacks** — deferred system callbacks (some TCP errors)
3. **idle, prepare** — internal
4. **poll** — I/O events; blocks here if nothing else is pending
5. **check** — `setImmediate`
6. **close callbacks** — `socket.on('close')`

Between every callback the microtask queues drain: `process.nextTick` queue
first, then promise callbacks. So `nextTick` beats `Promise.then`, and both beat
`setImmediate`.

## Template

```js
setTimeout(() => console.log('timeout'), 0);
setImmediate(() => console.log('immediate'));
Promise.resolve().then(() => console.log('promise'));
process.nextTick(() => console.log('nextTick'));
console.log('sync');

// sync, nextTick, promise, then timeout / immediate
// (timeout vs immediate order at the top level is not guaranteed —
//  inside an I/O callback, immediate always wins)
```

## When it bites

- CPU-heavy work (JSON parse of a huge payload, bcrypt, image resize) starves every
  other request. Move it to a worker thread or a child process.
- Recursive `process.nextTick` starves the loop entirely — the phase never advances.
- `fs.readFileSync` inside a request handler serialises your whole server.
- The libuv threadpool (default 4, `UV_THREADPOOL_SIZE`) backs `fs`, `dns.lookup`,
  `crypto.pbkdf2` — not network I/O, which is truly async at the OS level.

## Gotchas

- "Node is single-threaded" is only true of your JS. libuv has a threadpool; there
  are also worker threads.
- `setTimeout(fn, 0)` is clamped to 1ms.
- Unhandled promise rejections terminate the process by default since Node 15.

## Related

[[async]] · [[streams]] · [[_index]]
