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
| **Microtask** | Small work that runs between callbacks, not in its own phase. Both the nextTick queue and promise callbacks are microtasks. |
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

## Blocking the thread

> [!warning] Anything slow and synchronous stops the whole server
> `fs.readFileSync` in a request handler, a giant `JSON.parse`, a bcrypt round, or image work. One thread means one queue, and every other request waits. Move that work to a worker thread or another process.
