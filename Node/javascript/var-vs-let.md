# var vs let

> [!tldr]
> `var` is scoped to the whole function and can be redeclared. `let` is scoped to its block and cannot. Three interview questions come out of that difference.

---

## The comparison

| | `var` | `let` |
| --- | --- | --- |
| **Scope** | the entire function it was declared in | only the nearest block, meaning the nearest pair of curly braces |
| **Hoisting** | hoisted and set to `undefined`, so reading it early gives `undefined` | hoisted but unusable until the declaration runs, so reading it early throws a `ReferenceError` |
| **Redeclaration** | allowed in the same scope, which quietly hides bugs | throws a `SyntaxError` |
| **Use** | legacy code | everything you write now |

---

## Scope

```js
function example() {
  if (true) {
    var varVariable = 'I am a var variable';
    let letVariable = 'I am a let variable';
  }

  console.log(varVariable); // I am a var variable
  console.log(letVariable); // ReferenceError: letVariable is not defined
}
```

The `if` block is a boundary for `let` and invisible to `var`.

---

## Hoisting and the temporal dead zone

```js
function example() {
  console.log(varVariable); // undefined
  console.log(letVariable); // ReferenceError: Cannot access before initialization

  var varVariable = 'I am a var variable';
  let letVariable = 'I am a let variable';
}
```

Both names exist from the start of the function. The difference is that `var` starts holding `undefined`, while `let` starts in the **temporal dead zone**, a state where the name exists but touching it is an error. That is deliberate, because reading a variable before you set it is almost always a mistake, and `undefined` hides it.

---

## Redeclaration

```js
var v = 'first';
var v = 'second';   // fine, and this is the problem

let l = 'first';
let l = 'second';   // SyntaxError: Identifier 'l' has already been declared
```

---

## The loop question

This is the classic, and it is a scope question wearing a timer costume. Three versions, same loop bounds, three different outputs.

**Version 1: `var` with a closure.**

```js
for (var i = 0; i < 5; i++) {
  setTimeout(function () {
    console.log(i);
  }, 1000);
}
// 5 5 5 5 5
```

**Version 2: `var`, passing `i` as an argument.**

```js
for (var i = 0; i < 5; i++) {
  setTimeout(console.log, 1000, i);
}
// 0 1 2 3 4
```

**Version 3: `let` with a closure.**

```js
for (let i = 0; i < 5; i++) {
  setTimeout(function () {
    console.log(i);
  }, 1000);
}
// 0 1 2 3 4
```

All three verified on Node v22.16.0.

| Version | Prints | Because |
| --- | --- | --- |
| `var` plus a closure | `5` five times | there is one `i`, shared, read a second later when the loop has left it at 5 |
| `var` plus an argument | `0 1 2 3 4` | the value was copied into the timer's arguments at scheduling time |
| `let` plus a closure | `0 1 2 3 4` | each iteration gets its own `i` |

Two different fixes for the same symptom, and only one of them is about scope. Worth being able to name both, because an interviewer who shows you version 2 is checking whether you reach for "closure" as a reflex.

### The same thing at ten

```js
function print1To10() {
  for (var i = 1; i <= 10; i++) {
    setTimeout(() => console.log(i), 10);
  }
}

print1To10();
// 11, ten times
```

Same rule as version 1, and the final value is `11` rather than `10` because the loop only exits once the condition fails, which needs `i` to reach 11.
