# Scheduling Puzzles, Async and Await

> [!tldr]
> "What does this print" questions about how await suspends execution and hands control back, and when the microtask queue drains relative to other callbacks.

Part of [[puzzles-scheduling]].

---

## 7. resolve is not return

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

> [!example]- Answer
> ```text
> 1
> 2
> 3
> 5
> 6
> 4
> ```
> Two lessons. `resolve(4)` does not exit the function, so `5` still prints. And `await` hands control back to the caller, so `6` runs before the awaited value arrives.

---

## 8. Forgetting to await

```js
function fetchData() {
  return new Promise(resolve => {
    console.log('1');
    resolve('Data');
  });
}

function example() {
  console.log('Start');
  const data = fetchData();
  console.log(data);
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> 1
> Promise { 'Data' }
> End
> ```
> The promise body ran synchronously, so `1` prints. But `data` holds the promise, not the value, because nothing awaited it. Printing a promise object rather than your data is the everyday symptom of a missing `await`.

---

## 9. Code after an await

```js
function fetchData() {
  return new Promise(resolve => setTimeout(resolve, 1000, 'Data'));
}

function callback() {
  console.log('Callback');
}

async function example() {
  console.log('Start');
  await fetchData();
  callback();
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> (one second passes)
> Callback
> End
> ```
> Everything after the `await` waits, including plain synchronous calls.

---

## 10. nextTick before an await

```js
async function example() {
  console.log('Start');
  process.nextTick(callback);
  console.log('Mid');
  await fetchData();
  console.log('End');
}

example();
```

> [!example]- Answer
> ```text
> Start
> Mid
> Callback
> (one second passes)
> End
> ```
> The nextTick callback is queued, not run. `Mid` prints because that line is still synchronous. The queue drains as soon as the function suspends at the `await`, which is before the timer fires.

---

## 11. nextTick against then, no await anywhere

```js
console.log('Start');
process.nextTick(callback);
fetchData().then(() => console.log('Promise resolved'));
console.log('End');
```

> [!example]- Answer
> ```text
> Start
> End
> Callback
> (one second passes)
> Promise resolved
> ```
> Both logs run first because neither scheduled thing can interrupt synchronous code. `Callback` then goes ahead of the `then`, since the nextTick queue outranks promise callbacks.

---

## 12. Async IIFE

```js
(async () => {
  console.log('Start');
  const data = await fetchData();
  console.log(data);
  console.log('End');
})();
```

> [!example]- Answer
> ```text
> Start
> (one second passes)
> Data
> End
> ```
> Nothing surprising, and that is the point. This was the standard way to use `await` at the top of a file before top level await existed in ES Modules. See [[modules]].

---

## 14. The one that separates the queues

The hardest of the set. Trace both queues before reading the answer.

```js
console.log('1: Sync top');

setTimeout(() => {
  console.log('2: setTimeout 1');
  Promise.resolve().then(() => console.log('3: Promise in setTimeout 1'));
  process.nextTick(() => console.log('4: nextTick in setTimeout 1'));
}, 0);

setTimeout(() => {
  console.log('5: setTimeout 2');
}, 0);

Promise.resolve().then(() => {
  console.log('6: Promise 1');
  process.nextTick(() => console.log('7: nextTick in Promise 1'));
}).then(() => {
  console.log('8: Promise 2 (chained)');
});

process.nextTick(() => {
  console.log('9: nextTick 1');
  Promise.resolve().then(() => console.log('10: Promise in nextTick 1'));
});

async function asyncTest() {
  console.log('11: Async function start');
  await Promise.resolve();
  console.log('12: Async function end');
}

asyncTest();

console.log('13: Sync bottom');
```

> [!example]- Answer
> ```text
> 1, 11, 13, 9, 6, 12, 10, 8, 7, 2, 4, 3, 5
> ```
> Verified on Node v22.16.0. Unlike puzzles 3, 5 and 6, this one is fully deterministic, because there is no top level timer against immediate race.
>
> **Phase 1, synchronous.** Logs `1`. Both timers go to the timers queue. Promise `6` goes to the V8 microtask queue. `9` goes to Node's nextTick queue. The async function runs synchronously up to the `await`, so `11` logs and `12` is queued as a microtask. Logs `13`.
> Output so far: `1, 11, 13`.
>
> **Phase 2, the nextTick queue drains first.** Node always drains nextTick before V8's microtask queue. Logs `9`, which queues `10` as a microtask.
>
> **Phase 3, the trap.** Logs `6`, which schedules `7` on the nextTick queue. You might expect `7` to run immediately after `6`, since nextTick normally wins. It does not. **V8 does not know about Node's queues.** V8 finishes emptying its entire microtask queue, `12`, `10`, `8`, before handing control back to Node.
> Output so far: `1, 11, 13, 9, 6, 12, 10, 8`.
>
> **Phase 4, the second nextTick drain.** Node regains control and checks nextTick again before moving to timers. Logs `7`.
>
> **Phase 5, timers.** Logs `2`, which queues promise `3` and nextTick `4`. The second trap: in old Node, timer `5` would run next. Since Node 11 the loop drains microtasks between individual macrotasks, so nextTick runs first, logging `4`, then promises, logging `3`, and only then the next timer, `5`.
>
> The rule this teaches, which none of the earlier puzzles do: **nextTick beats promises only at the boundary where Node holds control.** Once V8 is draining its microtask queue, a nextTick scheduled mid drain waits for the whole queue to empty.
