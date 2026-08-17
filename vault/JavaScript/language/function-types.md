# Function Types

> [!tldr]
> The same JavaScript function gets classified four different ways: by whether it has a name, by how many arguments it takes, by how it behaves, and by whether it handles other functions.

---

## By name

| Kind | What it is | Catch |
| --- | --- | --- |
| **Named** | `function greet(name) {}`. Declared with the `function` keyword and an identifier. | Hoisted to the top of its scope, so you can call it before the line that declares it. |
| **Anonymous** | `var greet = function(name) {}`. A function expression with no identifier. | Cannot call itself by name. Usually passed as a callback. |
| **Arrow** | `const greet = (name) => {}`. Shorter, and it does not get its own `this`. | It borrows `this` from the surrounding scope, which is the whole point. |
| **IIFE** | `(function(){ ... })()`. Defined and run in the same breath. | Creates a private scope without leaking names into the global object. |

Arrow functions and regular functions handle `this` differently:

```js
function regularFunction() {
  console.log(this); // decided when the function is called
}

const arrowFunction = () => {
  console.log(this); // whatever this was outside the function
};

const obj = { name: 'John', regular: regularFunction, arrow: arrowFunction };

obj.regular(); // { name: 'John', regular: [Function: regularFunction], arrow: [Function: arrowFunction] }
obj.arrow();   // {}
```

An IIFE is how you built a module before modules existed:

```js
const myModule = (function () {
  let counter = 0;                       // private, nothing outside can touch it
  const incrementCounter = () => { counter++; };

  return {                               // only these two escape
    increment: () => { incrementCounter(); },
    getCounter: () => counter,
  };
})();

console.log(myModule.getCounter()); // 0
myModule.increment();
console.log(myModule.getCounter()); // 1
```

Nothing outside can touch `counter`. Only the two methods inside the returned object can access it.

---

## By number of arguments

| Name | Takes |
| --- | --- |
| **Nullary** | nothing. `function sayHello() {}` |
| **Unary** | exactly one argument. `function square(x) { return x * x; }` |

---

## By behaviour

**Pure.** Same input always gives the same output. Nothing outside the function changes. No network calls, no mutations except on data the function created.

```js
let counter = 0;

function impure() { counter += 1; }        // changes the outside world
function pure(counter) { return counter + 1; } // returns a new value instead
```

**Curried.** A function of three arguments becomes three functions of one argument each. This lets you supply arguments now and the rest later.

```js
// not curried
function multipleArgFunction(a, b, c) {
  return a + b + c;
}
console.log(multipleArgFunction(1, 2, 3)); // 6

// curried, written out
function curryFunction1(a) {
  return function (b) {
    return function (c) {
      return a + b + c;
    };
  };
}

// curried, as arrows
const curryFunction2 = (a) => (b) => (c) => a + b + c;

console.log(curryFunction1(1)(2)(3)); // 6
console.log(curryFunction2(1)(2)(3)); // 6
```

The arrow form is what you write. The nested form is what it means. An interviewer checks whether you can write both.

**Constructor.** Called with `new`, and it builds an object.

```js
function Person(name, age) {
  this.name = name;
  this.age = age;
}
const person = new Person('Alice', 30);
```

---

## By how they treat other functions

| Name | Means |
| --- | --- |
| **First class** | Functions are values. You can put one in a variable, pass it, or return it. This is a fact about the language. |
| **Higher order** | Takes a function as an argument, or returns one. `arr.map(fn)` or a curried function. |
| **First order** | Does neither. Works only on data. |

---

## Generators

A function that can pause. Use `function*` and `yield`. Each call to `next()` runs until the next `yield`.

```js
function* generateUserIds() {
  let i = 0;
  while (true) {
    yield i++;
  }
}

const ids = generateUserIds();
ids.next().value; // 0
ids.next().value; // 1
```

> [!tip] Why an infinite loop is safe here
> The `while (true)` never runs to completion. It stops at `yield` and waits. A generator can describe an endless sequence without hanging.
