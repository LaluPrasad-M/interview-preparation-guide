# Worker Threads

> [!tldr]
> Node runs your JavaScript on one thread, so CPU heavy work blocks every request. A worker thread runs that work on a separate thread and messages the result back.

> [!question] This note is not from your notebook
> The source notebook has the heading and then stops, with no example cells. Everything below is written from scratch, so check it against a source you trust before revising from it.

---

## When you need one

| Work | Needs a worker |
| --- | --- |
| Reading a file, calling an API, querying a database | no. Node already does these without blocking |
| Parsing a very large JSON payload, resizing an image, hashing a password, heavy maths | yes |

The test is simple. If the work is waiting, Node handles it already. If the work is thinking, it occupies the one thread and everything else queues behind it. See [[event-loop]].

---

## The shape of it

```js
// main.js
const { Worker } = require('node:worker_threads');

function runHeavyTask(input) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./heavy-task.js', { workerData: input });

    worker.on('message', resolve);
    worker.on('error', reject);
    worker.on('exit', code => {
      if (code !== 0) reject(new Error(`Worker stopped with code ${code}`));
    });
  });
}

const result = await runHeavyTask({ numbers: [1, 2, 3] });
```

```js
// heavy-task.js
const { parentPort, workerData } = require('node:worker_threads');

const total = workerData.numbers.reduce((sum, n) => sum + n, 0);

parentPort.postMessage(total);
```

Wrapping the worker in a promise is the part worth copying. The events are the raw API, and nobody wants to handle three listeners at every call site.

---

## What crosses the boundary

Messages are copied, not shared. They use the same algorithm as `structuredClone` (see [[deep-clone]]). Functions cannot be sent. The object the worker receives is a separate object from the one you sent.

The exception is `SharedArrayBuffer`, which really is shared memory. That buys speed and brings back every problem [[locks]] exists to solve, so reach for it only when copying is measurably too slow.

---

## Threads against processes

| | Worker thread | Child process or cluster |
| --- | --- | --- |
| Memory | shares the process, cheaper to start | its own memory space |
| Crash | can take the process down | isolated |
| Use for | CPU heavy work inside one service | running several copies of a server across CPU cores |

> [!warning] Do not start a worker per request
> Starting a thread costs real time and memory, so a worker per request under load is slower than doing the work inline. Keep a small pool of workers alive and hand tasks to whichever one is free, the same idea as the concurrency pool in [[timers-and-concurrency]].
