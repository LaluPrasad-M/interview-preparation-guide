# Scheduling Puzzles

> [!tldr]
> Every "what does this print" question about the event loop, with the answer folded away. Read the code, commit to an answer, then unfold. The rules behind them are in [[event-loop]].

Where a puzzle below uses `fetchData` or `callback` without defining them, they are these. This `fetchData` takes no arguments, unlike the parameterised one in [[puzzles-promises]], because none of these puzzles need to vary the delay:

```js
function fetchData() {
  return new Promise(resolve => setTimeout(resolve, 1000, 'Data'));
}

function callback() {
  console.log('Callback');
}
```

---

## 0. The baseline

Nothing scheduled at all, so the answer is boring. Worth one look, because every puzzle below is a departure from it.

```js
function syncFunction() {
  console.log('Synchronous function');
}

console.log('Start');
syncFunction();
console.log('End');
```

> [!example]- Answer
> ```text
> Start
> Synchronous function
> End
> ```
> Top to bottom, no queue involved.

---

## 1. setTimeout with zero delay

```js
console.log('first');
setTimeout(() => console.log('second'), 0);
console.log('third');
```

> [!example]- Answer
> ```text
> first
> third
> second
> ```
> Zero delay does not mean now. The callback waits until the synchronous code finishes and the loop reaches the timers phase.

---

## 2. Passing arguments to the callback

```js
console.log('one');
setTimeout(console.log, 0, 'two');
console.log('three');
```

> [!example]- Answer
> ```text
> one
> three
> two
> ```
> Same ordering. The extra arguments after the delay are handed to the callback, so you avoid wrapping it in an arrow function.

---

## 3. Timeout against immediate

```js
console.log('start');
setTimeout(console.log, 0, 'timeout');
setImmediate(console.log, 'immediate');
console.log('end');
```

> [!example]- Answer
> ```text
> start
> end
> then timeout and immediate, in an order that is not guaranteed
> ```
> At the top level the winner depends on how long the process took to start. Inside an I/O callback, `setImmediate` always runs first. If you are asked for a definite answer, that distinction is the answer.

---

## 4. nextTick beats the timer

```js
console.log('Start');
setTimeout(console.log, 0, 'setTimeout');
process.nextTick(() => console.log('process.nextTick'));
process.nextTick(console.log, 'process.nextTick 2');
console.log('End');
```

> [!example]- Answer
> ```text
> Start
> End
> process.nextTick
> process.nextTick 2
> setTimeout
> ```
> The nextTick queue drains completely as soon as the current operation finishes, before the loop moves on to timers. Two nextTicks run in the order they were queued.

---

## 5. Everything at once

```js
setImmediate(() => console.log('setImmediate'));
setTimeout(() => console.log('setTimeout'), 0);

new Promise((resolve) => {
  console.log('Promise');
  resolve('Promise resolved');
}).then(res => console.log('Promise then', res));

process.nextTick(() => console.log('process.nextTick'));

console.log('World');
```

> [!example]- Answer
> ```text
> Promise
> World
> process.nextTick
> Promise then Promise resolved
> ```
> then `setTimeout` and `setImmediate`, in an order that is not guaranteed.
>
> The `new Promise` body runs immediately and synchronously, which is why `Promise` prints first, before `World`. Then microtasks: nextTick, then promise callbacks.
>
> The last two are the same top level race as puzzle 3. Forty runs on this machine all printed `setTimeout` then `setImmediate`, but that is the common case, not a rule. Move the pair inside an I/O callback and `setImmediate` always wins.

---

## 6. Nested scheduling

```js
console.log('Start');

setTimeout(() => {
  console.log('setTimeout 1');
  process.nextTick(() => console.log('process.nextTick 1'));
  setImmediate(() => console.log('setImmediate 1'));
}, 0);

setImmediate(() => {
  console.log('setImmediate 2');
  process.nextTick(() => console.log('process.nextTick 2'));
  setTimeout(() => console.log('setTimeout 2'), 0);
});

console.log('End');
```

> [!example]- Answer
> **There is no single answer, and that is the answer.** Forty runs on Node v22.16.0 produced three different orders:
>
> ```text
> 35 runs: Start End setImmediate 2 nextTick 2 setTimeout 1 nextTick 1 setTimeout 2 setImmediate 1
>  4 runs: Start End setTimeout 1 nextTick 1 setImmediate 2 nextTick 2 setImmediate 1 setTimeout 2
>  1 run:  Start End setImmediate 2 nextTick 2 setTimeout 1 nextTick 1 setImmediate 1 setTimeout 2
> ```
>
> So there is a common case, not a rule. Anyone who tells you this snippet has one correct output has run it once.
>
> What is guaranteed:
>
> - `Start` and `End` first. Nothing scheduled can interrupt synchronous code.
> - After **every** callback, the nextTick queue drains before anything else. That is why `nextTick 1` always lands immediately after `setTimeout 1`, and `nextTick 2` immediately after `setImmediate 2`, in all three orders. Those pairs never come apart, and that is the part worth saying out loud.
>
> What is not guaranteed: which of the timer and the immediate goes first. A `setTimeout(fn, 0)` is really a one millisecond timer, so whether it is ready when the loop first checks depends on how long the process took to start. Puzzle 3 says the same thing with fewer moving parts.
>
> If an interviewer wants a definite order here, the honest answer is to name the pairing rule, then say the timer against immediate race is not deterministic at the top level, and that inside an I/O callback `setImmediate` always wins.

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
