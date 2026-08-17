# Overloading against Overriding

> [!tldr]
> Overriding is runtime polymorphism achieved by prototype shadowing. Overloading is compile time only, and JavaScript does not have it at all.

---

## Method overriding, runtime polymorphism

A child class provides a new specific implementation for a method already defined in its parent. The signature, meaning name and parameters, stays identical.

**In JavaScript** it is natively supported via the prototype chain, using property shadowing. The engine stops searching as soon as it finds the method on the child's prototype.

**In TypeScript** there are additional compile time checks ensuring the child signature exactly matches the parent's, plus the `override` keyword preventing accidental typos.

```ts
class GenericDB {
  connect(uri: string): void { console.log(`Connecting: ${uri}`); }
}

class MongoDB extends GenericDB {
  // TS ensures 'connect' exists in the parent and the signatures match.
  // The 'override' keyword is a TS only safety net.
  override connect(uri: string): void {
    console.log(`Mongo specific connection pooling for ${uri}`);
  }
}
// Under the hood: the 'override' keyword and type annotations are erased.
```

```js
class GenericDB {
  connect(uri) { console.log(`Connecting: ${uri}`); }
}

class MongoDB extends GenericDB {
  connect(uri) {
    console.log(`Mongo specific connection pooling for ${uri}`);
  }
}

// Under the hood, prototype chain resolution:
// 1. You call new MongoDB().connect("uri")
// 2. The engine looks at the instance object first. Not there.
// 3. It looks at MongoDB.prototype. Found 'connect', so it executes it.
// 4. It completely ignores GenericDB.prototype.connect, because it found a
//    match earlier in the chain. That is shadowing.
```

---

## Method overloading, compile time polymorphism

Method overloading defines multiple methods with the same name but different signatures, meaning a different number or type of parameters. It provides optional arguments while hiding the implementation from the caller.

**JavaScript does not support it.** If you write two functions with the same name, the second completely replaces the first in memory. You simulate it by inspecting the `arguments` object or checking parameter types.

**TypeScript supports it natively** using overload signatures. You declare multiple signatures for the caller, but write only one implementation signature containing the actual logic.

```ts
class DataService {
  // 1. Declaration signatures, what the compiler sees and enforces
  fetch(id: number): string;
  fetch(id: number, returnAsArray: boolean): string[];

  // 2. Implementation signature, the actual logic, hidden from the caller
  fetch(id: number, returnAsArray?: boolean): any {
    const data = `Data for ${id}`;
    if (returnAsArray) return [data];
    return data;
  }
}
// Under the hood: the declaration signatures are stripped entirely.
// Only the single implementation signature compiles to JavaScript.
```

```js
class DataService {
  // Since JS has no overloads, the latest definition wins.
  // We write one function and manually inspect the arguments.
  fetch(id, returnAsArray) {
    const data = `Data for ${id}`;

    // Simulating the overload logic dynamically at runtime
    if (typeof returnAsArray === 'boolean' && returnAsArray) {
      return [data];
    }
    return data;
  }
}

// Under the hood: the engine just passes 'undefined' to 'returnAsArray'
// if the caller omits it. The developer handles missing or differently
// typed arguments entirely.
```

---

## The interview answers

### How does V8 process two functions with the same name?

"Because JavaScript is dynamically typed, it does not support method overloading. If I define `processData(id)` and immediately below define `processData(id, options)`, the engine completely overwrites the first function reference with the second. The last declaration always wins.

To achieve overloading behaviour in pure JavaScript, I simulate it within a single function body. I write one method accepting the maximum possible parameters and inspect the arguments at runtime, checking `arguments.length`, verifying whether a parameter is `undefined`, or using `typeof` to determine the shape. If the second argument is a function, I treat it as a callback. If it is an object, I treat it as options.

In TypeScript I can achieve true overloading. I provide multiple declaration signatures defining the exact parameter shapes without bodies, followed by one implementation signature holding the logic. The compiler enforces these during development, then strips the declarations and compiles down to that single manually inspected JavaScript function."

### How does overriding work mechanically?

"Method overriding works through property shadowing on the prototype chain.

When a child class extends a parent, the child's `.prototype` is linked to the parent's `.prototype` via the hidden `[[Prototype]]` reference. When I instantiate the child and invoke a method, the engine begins a lookup. First it checks the instance object. If the method is not there, it moves up to the child's `.prototype`.

If the child overrode the method, the engine finds it there, executes it, and stops searching. It never reaches the parent's `.prototype` where the original lives. The child's method shadows the parent's.

If I need the parent's logic from inside the overridden method, I explicitly call `super.methodName()`, which tells the engine to bypass the immediate prototype and execute the function one step higher on the chain."
