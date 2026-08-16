# Closures

> [!tldr]
> A function remembers the variables that surrounded it when it was created, even after the outer function has finished. That memory is the closure.

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

`outer` has already returned by the time `inner` runs, so `x` should be gone. It is not, because `inner` kept a reference to the scope it was born in.

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
> `var x = 10` inside `inner` creates a local `x` for the whole of `inner`, so the outer `x` is invisible in there. The log runs before the assignment, so it prints `undefined`. Swap `var` for `let` and it throws instead, because of the temporal dead zone. See [[var-vs-let]].

The rule underneath: a scope's variables are decided by where the code is written, not by what is happening when it runs. That is what lexical scoping means.

---

## The counter, the canonical example

```javascript
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

---

## The three reasons to use them

**Data privacy, meaning encapsulation.** Before `#private` fields existed, closures were the only way to hide variables in JavaScript.

**Currying and partial application.**

```javascript
const add = a => b => a + b;
```

**Memoization.** Caching expensive function calls, where the cache lives in the closure rather than as a global.

---

## Why interviewers like it

Closures are how you get private state in a language with no `private` keyword. The counter inside an IIFE, the `release` function a mutex hands back, the callback that still knows which request it belonged to. All the same mechanism.
