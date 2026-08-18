# this Binding

> [!tldr]
> `call`, `apply` and `bind` are three ways to tell a function what `this` should be. Two run now, one hands you a new function for later.

---

## The comparison

| | Runs now | Arguments | Returns |
| --- | --- | --- | --- |
| **call** | yes | comma separated | whatever the function returns |
| **apply** | yes | as an array | whatever the function returns |
| **bind** | no | comma separated, remembered for later | a new function with `this` fixed |

The only difference between `call` and `apply` is how you pass arguments. Use `apply` when you already have them in an array.

---

## All three, same function

```js
function greet(message) {
  console.log(`${message}, ${this.name}!`);
}

const person = { name: 'John' };

greet.call(person, 'Hello');        // Hello, John!
greet.apply(person, ['Hello']);     // Hello, John!

const boundGreet = greet.bind(person, 'Hello');
boundGreet();                       // Hello, John!
```

---

> [!tip] When bind actually matters
> Passing a method strips its `this`. `setTimeout(obj.method, 100)` loses the object. Pass `obj.method.bind(obj)` instead. An arrow function solves this by never having its own `this`.
