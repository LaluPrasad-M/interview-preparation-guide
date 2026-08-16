# Engine Internals

> [!tldr]
> Before a single line runs, the engine builds an execution context in two phases. Almost every hoisting, `this` and TDZ question falls out of that one fact.

---

## The execution context and hoisting

### Phase 1: creation, memory allocation

The engine parses the code and allocates memory for variables and functions before executing anything.

**Functions** are fully hoisted, with the entire body placed into memory.

**`var` variables** are hoisted and initialised with `undefined`.

**`let` and `const`** are hoisted but not initialised. They sit in the temporal dead zone.

### Phase 2: execution

The engine runs line by line, assigning actual values and executing calls.

> [!warning] The hoisting gotcha
> Function declarations are hoisted fully. Function expressions, assigned to variables, are hoisted based on their variable keyword.

```javascript
// How the engine sees your code
console.log(sayHi()); // "Hi", fully hoisted
console.log(name);    // undefined, var is hoisted but not initialised
console.log(age);     // ReferenceError, let is in the TDZ
console.log(sayBye);  // undefined, var is hoisted but not the function assignment
sayBye();             // TypeError: sayBye is not a function

function sayHi() { return "Hi"; } // function declaration
var name = "Rahul";
let age = 30;
var sayBye = function() { return "Bye"; } // function expression
```

---

## The five `this` binding rules

`this` evaluates at runtime based entirely on how a function is called, not where it is written. Five rules, in this order of precedence.

### 1. New binding, highest precedence

When a function is called with `new`, `this` points to the newly created empty object.

```javascript
function User(name) { this.name = name; }
const u = new User("Rahul"); // 'this' inside User points to 'u'
```

### 2. Explicit binding

You explicitly tell the engine what `this` should be.

`.call(obj, arg1, arg2)` executes immediately. `.apply(obj, [arg1, arg2])` executes immediately taking an array of arguments. `.bind(obj)` returns a new function permanently bound to `obj`.

See [[this-binding]] for the full comparison.

### 3. Implicit binding, object dot notation

If a function is called as a method on an object, `this` points to the object immediately left of the dot.

```javascript
const user = {
    name: "Rahul",
    greet() { console.log(this.name); }
};
user.greet(); // 'this' is user, prints "Rahul"
```

### 4. Default binding, the global object

If a standalone function is called without any context, `this` defaults to the global object, `window` in browsers and `global` in Node. In strict mode, default binding is `undefined`.

> [!warning] The losing `this` problem
> Extracting a method loses its implicit binding.
> ```javascript
> const detachedGreet = user.greet;
> detachedGreet(); // Nothing left of the dot, so 'this' falls back to default binding
> ```

### 5. Lexical binding, arrow functions

Arrow functions do not have their own `this`. They lexically resolve it by looking up the scope chain to the nearest surrounding normal function or global scope.

You cannot `.bind()`, `.call()`, or use `new` on an arrow function.

---

## Prototypal inheritance

JavaScript does not have real classes. It has objects linked to other objects.

### `prototype` against `__proto__`

**`prototype`** is a special property that exists only on functions. It is the blueprint that will be attached to instances created by that function.

**`__proto__`**, also written `[[Prototype]]`, exists on all objects. It is the hidden link pointing to its creator's `prototype`.

```javascript
function Animal() {}
Animal.prototype.eat = function() { console.log("Eating"); };

const dog = new Animal();

console.log(dog.__proto__ === Animal.prototype); // true
console.log(Animal.prototype.__proto__ === Object.prototype); // true
```

### Chain resolution

When you call `dog.eat()`:

1. The engine checks the `dog` object directly. Not found.
2. It follows `dog.__proto__` up to `Animal.prototype`. Found, so it executes.
3. If not found there, it goes to `Object.prototype`.
4. If still not found, it reaches `null` and returns `undefined`, or throws a TypeError if called as a function.

See [[prototypes-and-classes]] for how ES6 classes sit on top of this.

### `Object.create()`, true prototypal inheritance

Creates a new object and explicitly sets its `__proto__` to a specified object, bypassing constructor functions entirely.

```javascript
const animalMethods = { eat() { console.log("eating"); } };
const dog = Object.create(animalMethods); // dog.__proto__ points to animalMethods
```

---

## The concurrency model

JavaScript is single threaded, with one call stack. The event loop is how it handles async work without freezing.

**Heap.** Memory allocation for objects.

**Call stack.** Where functions are pushed to execute, last in first out.

**Web APIs or Node APIs.** Background threads handling `setTimeout`, DOM events and HTTP requests.

**Task queue, macrotasks.** Callbacks for `setTimeout`, `setInterval`, UI rendering and I/O.

**Microtask queue.** Callbacks for promises, `.then` and `.catch`, and `MutationObserver`.

The event loop continuously checks the call stack, and when it is empty pushes tasks from the queues.

> [!tip] The priority rule
> The microtask queue has absolute priority. The event loop empties the entire microtask queue before processing a single macrotask.

```javascript
console.log("1. Start");

setTimeout(() => console.log("2. Macrotask"), 0);

Promise.resolve().then(() => console.log("3. Microtask"));

console.log("4. End");

// Output order:
// 1. Start      (synchronous call stack)
// 4. End        (synchronous call stack)
// 3. Microtask  (microtask queue gets priority)
// 2. Macrotask  (task queue runs last)
```

See [[event-loop]] for the full Node ordering including `process.nextTick`.

---

## Memory management

### Stack against heap

**Stack.** Stores primitives, meaning string, number, boolean, null and undefined, plus object references, the pointers. Access is very fast.

**Heap.** Stores objects, arrays and functions. An unstructured memory pool, slower to access.

### Garbage collection, mark and sweep

The engine periodically runs a garbage collector.

1. It starts at the roots, the global object.
2. It traverses all references and marks every object it can reach.
3. Any heap object that is not marked, meaning unreachable, is swept and deleted to free memory.

**Memory leaks** happen when you accidentally keep references to objects you do not need, for example a forgotten `setInterval` or an undeleted DOM event listener.

### The temporal dead zone

With `let` or `const`, variables are hoisted to the top of their block but remain uninitialised, in the TDZ.

You cannot access a variable in the TDZ. The zone ends the moment execution reaches the declaration line.

```javascript
{
    // TDZ for 'name' starts here
    console.log(name); // ReferenceError
    let name = "Rahul"; // TDZ ends here
}
```
