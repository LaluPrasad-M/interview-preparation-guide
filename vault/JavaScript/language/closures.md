# Closures

> [!tldr]
> A function remembers the variables from the scope where it was created, even after the outer function finishes. That memory is the closure.

---

## The plain version

```js
function outer() {
  const x = 10;
  function inner() {
    return x ** 2;
  }
  return inner;
}

const closureFn = outer();
console.log(closureFn()); // 100
```

`outer` has already returned when `inner` runs, so `x` should be gone. It is not. `inner` kept a reference to the scope where it was born.

---

## Where it goes wrong

```js
const x = 5;
function outer() {
  console.log(x, 'before');   // 5
  function inner() {
    console.log(x);           // ReferenceError with let, undefined with var
    var x = 10;
  }
  inner();
  console.log(x, 'after');    // 5
}
outer();
```

> [!warning] The inner declaration wins before it exists
> `var x = 10` inside `inner` creates a local `x` for the whole of `inner`, so the outer `x` is invisible inside it. The log runs before the assignment, so it prints `undefined`. Swap `var` for `let` and it throws instead, because of the temporal dead zone. See [[var-vs-let]].

A scope's variables are decided by where the code is written, not by what happens when it runs. That is what **lexical scoping** means.

---

## The counter example

```js
function createCounter() {
    let count = 0; // lives in the closure memory space
    return function increment() {
        count++; // remembers 'count' even after createCounter() finished
        console.log(count);
    }
}
const counter = createCounter();
counter(); // 1
counter(); // 2
```

Each call to `createCounter` makes a new `count` variable. That variable lives on, remembered by the returned function, even though `createCounter` has finished.

---

## Three reasons to use closures

**Data privacy.** Before `#private` fields existed, closures were the only way to hide variables in JavaScript.

**Currying and partial application.**

```js
const add = a => b => a + b;
```

**Memoization.** Cache the result of an expensive function call. The cache lives in the closure, not as a global.

---

## Why interviewers ask about closures

Closures give you private state without a `private` keyword. The counter inside an IIFE, the `release` function a mutex hands back, the callback that remembers which request it belongs to. All the same mechanism.
