# Scheduling Puzzles, Timing Fundamentals

> [!tldr]
> "What does this print" questions about zero delay, timing phases, and the race between setTimeout and setImmediate. Each comes with an answer.

Part of [[puzzles-scheduling]].

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
