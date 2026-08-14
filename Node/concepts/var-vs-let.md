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

## Hoisting and the temporary dead zone

```js
function example() {
  console.log(varVariable); // undefined
  console.log(letVariable); // ReferenceError: Cannot access before initialization

  var varVariable = 'I am a var variable';
  let letVariable = 'I am a let variable';
}
```

Both names exist from the start of the function. The difference is that `var` starts holding `undefined`, while `let` starts in the **temporary dead zone**, a state where the name exists but touching it is an error. That is deliberate, because reading a variable before you set it is almost always a mistake, and `undefined` hides it.

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

This is the classic, and it is a scope question wearing a timer costume.

```js
function print1To10() {
  for (var i = 1; i <= 10; i++) {
    setTimeout(() => console.log(i), 10);
  }
}
```

> [!warning] It prints 11, ten times
> There is only one `i`, because `var` belongs to the function, not the loop. All ten callbacks close over that same variable, and by the time they run the loop has finished and left `i` at 11.
>
> Change `var` to `let` and it prints 1 to 10, because `let` creates a fresh `i` for every iteration.
