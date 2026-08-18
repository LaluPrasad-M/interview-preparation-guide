# Event Loop and Callback Order

> [!tldr]
> Node runs your JavaScript on one thread. Four different ways to schedule work run in a fixed order, and interview questions are almost always about that order.

---

## The order, highest priority first

| Scheduled with | When it runs |
| --- | --- |
| `process.nextTick()` | immediately after the current operation finishes, before anything else |
| a resolved `Promise` | right after the nextTick queue drains, still before timers |
| `setTimeout(fn, 0)` | in the timers phase of the next loop iteration |
| `setImmediate()` | in the check phase, after the poll phase where I/O is handled |

The names are misleading. `setImmediate` is not immediate. `process.nextTick` does not wait for the next tick. Learn them by their position in the queue, not by their English meaning.

Three words used above are worth pinning down, because everything else builds on them.

| Word | Means |
| --- | --- |
| **Microtask** | Small work that runs between callbacks, not in its own phase. The nextTick queue, promise callbacks, `queueMicrotask` and everything after an `await` are all microtasks. |
| **Poll** | The phase where the loop waits for I/O. This is where it blocks when there is nothing else to do. |
| **Check** | The phase right after poll. It exists to run `setImmediate`. That is why `setImmediate` runs after I/O, not before. |

---

## The question you will be asked

```js
console.log('Start');

setTimeout(console.log, 0, 'setTimeout');
setImmediate(console.log, 'setImmediate');
Promise.resolve().then(() => console.log('Promise'));
process.nextTick(() => console.log('nextTick'));

console.log('End');
```

Output:

```text
Start
End
nextTick
Promise
setTimeout
setImmediate
```

The two synchronous logs go first. Nothing scheduled can run while your code is still running. Then the microtasks: `nextTick` before `Promise`. Then the timer, then the check phase.

> [!warning] setTimeout before setImmediate is not guaranteed
> At the top level the order between those two depends on how long the process took to start. Inside an I/O callback, `setImmediate` always wins. If an interviewer asks for a firm answer, that distinction is the answer.

---

## Why process.nextTick exists at all

Two honest reasons.

**To finish the current function before anything else runs.** You want the caller to get its return value, and only then have your callback fire, still ahead of any I/O.

```js
function api() {
  validate();
  process.nextTick(() => emitEvent());
}
```

**Because Node's own internals rely on it.** It predates promises and a lot of core code is built on its exact position in the queue, so it is not going away.

> [!warning] nextTick can starve the loop completely
> The nextTick queue drains fully before the loop moves on, so a callback that schedules itself never lets the loop continue.
>
> ```js
> function loop() {
>   process.nextTick(loop);
> }
> loop();
> ```
>
> No timer fires, no I/O callback runs, no request gets served, and CPU sits at 100 percent with no error in the logs. Use `setImmediate` when you want to yield between iterations.

---

## The one that gets people

```js
function main() {
  return new Promise(resolve => {
    console.log(3);
    resolve(4);
    console.log(5);
  });
}

async function f() {
  console.log(2);
  const r = await main();
  console.log(r);
}

console.log(1);
f();
console.log(6);
```

Output is `1 2 3 5 6 4`.

The body of a `new Promise` runs immediately and synchronously. So 3 and 5 print in order. `resolve(4)` does not stop the function. `await` passes control back to the caller, so 6 prints before 4.

---

## The six phases, name by name

The four-row table above is the interview shortcut. The full picture is libuv running six phases in a loop, in this order:

| Phase | Handles |
| --- | --- |
| Timers | callbacks scheduled by `setTimeout` and `setInterval` whose time has passed |
| Pending callbacks | callbacks for some system operations, like certain TCP errors, deferred from the previous loop iteration |
| Idle, prepare | internal use only, not something application code schedules into |
| Poll | fetches new I/O events, executes I/O related callbacks. This is where the loop blocks if there is nothing else to do |
| Check | runs `setImmediate` callbacks, right after poll |
| Close callbacks | `close` event handlers, for example `socket.on('close', ...)` |

> [!warning] There is no single "macrotask queue"
> People say microtask queue against macrotask queue as if both were one queue each. Microtasks are one queue, drained after every callback. The other side is six phases, each with its own queue, which is why `setTimeout` and `setImmediate` do not compete with each other in any fixed way at the top level.

> [!tip] Poll is where the loop actually waits
> Every other phase runs its queue and moves on. Poll is the one phase that can block, holding the loop open while it waits for I/O, which is also why `setImmediate` (check phase) reliably runs right after any I/O callback (poll phase).

That block is where Node's efficiency comes from, and it is worth saying out loud in an interview.
With nothing ready to run, the loop does not keep spinning and checking. It hands over to the operating system and sleeps until an event arrives, so an idle server uses almost no CPU. A loop that polled in a `while (true)` instead would burn a core doing nothing.

---

## Blocking the thread

> [!warning] Anything slow and synchronous stops the whole server
> `fs.readFileSync` in a request handler, a giant `JSON.parse`, a bcrypt round, or image work. One thread means one queue, and every other request waits. Move that work to a worker thread or another process.

> [!warning] Streaming does not fix CPU work
> Switching a heavy operation to a stream fixes memory pressure, not blocking. `stream.on('data', chunk => cpuHeavyWork(chunk))` still runs `cpuHeavyWork` synchronously on the main thread for every chunk. Streams solve "do not load the whole file into memory", not "do not block the event loop". CPU-bound work still needs a worker thread or another process regardless of whether the input arrived as a stream or a buffer.

---

## One message, traced through the phases

A WebSocket server reads a file and processes it. Following one message makes the phases concrete.

1. The message arrives. libuv sees the socket event and the **poll** phase runs your `ws.on("message", handler)` callback.
2. The handler calls `fs.readFile`. That does not happen on the event loop. It goes to the libuv thread pool, four threads by default, and the loop carries on.
3. The read finishes. The thread pool hands the callback back, and it runs in the **poll** phase on the next time around.
4. That callback calls `processFile(data)`, which takes 2 seconds of CPU.

Step 4 is where it goes wrong. For those 2 seconds no message is handled, no timer fires, and no I/O callback runs, because there is one thread and it is busy.

New messages still arrive during the block. The OS receives the packets and libuv notes the events, but nothing is processed, so they sit in the poll queue and every client sees the delay. When `processFile` returns, the loop drains the backlog and `ws.send(result)` finally goes out.

The fix is not a faster `processFile`, it is getting it off this thread, see [[worker-threads]] and [[async-processing-and-queues]].

> [!tip] Where the other schedulers land in that trace
> A `setImmediate` inside the read callback runs in the **check** phase, straight after poll. A resolved promise runs as a microtask, after the current callback and before the next phase. Neither one yields during `processFile`, because nothing yields in the middle of synchronous code.
