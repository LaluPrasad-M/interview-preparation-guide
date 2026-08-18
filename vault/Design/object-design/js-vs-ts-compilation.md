# The Four Pillars: JavaScript against TypeScript Under the Hood

> [!tldr]
> TypeScript's `private` is fake encapsulation. It exists for tooling and is stripped at compile time. JavaScript's `#` is enforced by the engine at runtime.

---

## Encapsulation

Encapsulation bundles data and methods into a single unit, and restricts direct outside access to internal state.

**The distinction.** TypeScript access modifiers `private` and `protected` only exist at compile time. Once compiled, those properties become entirely public. Modern JavaScript uses the `#` prefix, strictly enforced at runtime by the engine via hidden internal slots.

```typescript
class TSConsumer {
  // The TS compiler enforces privacy here
  private secret: string;

  constructor(secret: string) {
    this.secret = secret;
  }
}
// Under the hood: compiles to public JavaScript.
// const tsc = new TSConsumer("key");
// console.log(tsc.secret); // works perfectly at runtime
```

```javascript
class JSConsumer {
  // The engine enforces true privacy here
  #secret;

  constructor(secret) {
    this.#secret = secret;
  }
}
// Under the hood: truly private.
// const jsc = new JSConsumer("key");
// console.log(jsc.#secret);
// SyntaxError: Private field '#secret' must be declared in an enclosing class
```

---

## Abstraction

Abstraction hides low level implementation details and exposes only the necessary high level interface.

**The distinction.** TypeScript has native `interface` and `abstract class`. JavaScript has neither, so abstraction must be enforced at runtime by throwing errors.

```typescript
abstract class BaseProcessor {
  abstract process(): void; // contract enforced by the compiler
}

class ConcreteProcessor extends BaseProcessor {
  process() { console.log("Processing"); }
}
// Under the hood: the 'abstract' keyword is stripped entirely,
// and interfaces disappear completely from the compiled output.
```

```javascript
class BaseProcessor {
  constructor() {
    if (new.target === BaseProcessor) {
      throw new Error("Cannot instantiate abstract class");
    }
  }
  process() {
    // Runtime contract enforcement
    throw new Error("Method 'process()' must be implemented");
  }
}
```

---

## Inheritance and the prototypal conversion

Inheritance means a class acquires properties and behaviours from a parent class. In backend work we strictly favour composition over inheritance, to avoid fragile base classes and tight coupling. See [[inheritance-vs-composition]].

**The distinction.** JavaScript has no traditional classes. The ES6 `class` keyword is syntactic sugar over constructor functions and the prototype chain. When targeting older engines, the TypeScript compiler generates a helper called `__extends` to wire the chain manually.

```javascript
// ES6 syntax, what you write
class Parent {
  greet() { return "Hello"; }
}
class Child extends Parent {}

// Under the hood, the prototypal conversion
function ParentUnderTheHood() {}
ParentUnderTheHood.prototype.greet = function() { return "Hello"; };

function ChildUnderTheHood() {
  // 1. Call the parent constructor with the current context
  ParentUnderTheHood.call(this);
}

// 2. Wire up the instance prototype chain, inheriting methods
ChildUnderTheHood.prototype = Object.create(ParentUnderTheHood.prototype);
ChildUnderTheHood.prototype.constructor = ChildUnderTheHood;

// 3. Wire up the static prototype chain, inheriting static methods
Object.setPrototypeOf(ChildUnderTheHood, ParentUnderTheHood);
```

```typescript
// Inheritance, tight coupling
class Database { save() {} }
class UserDB extends Database {}

// Under the hood targeting ES5: TypeScript generates a __extends helper
// that copies static properties from parent to child, and sets
// Child.prototype = Object.create(Parent.prototype).

// Composition, loose coupling, the preferred approach
interface Storage { save(): void; }
class PostgresStorage implements Storage { save() {} }

class UserService {
  // A has-a relationship, independent of hierarchy
  constructor(private storage: Storage) {}
  createUser() { this.storage.save(); }
}
// Under the hood: compiles to simple constructor assignments
// without complex prototype chains.
```

---

## Polymorphism

Different classes respond to the same method call, each based on its own implementation.

**The distinction.** TypeScript enforces polymorphism structurally via interfaces. JavaScript enforces it dynamically via duck typing: if it has the method, it works.

```typescript
interface Logger { log(): void; }
class FileLogger implements Logger { log() { console.log("File"); } }
class DBLogger implements Logger { log() { console.log("DB"); } }

function executeLog(logger: Logger) { // TS ensures logger has log()
  logger.log();
}
```

```javascript
class FileLogger { log() { console.log("File"); } }
class DBLogger { log() { console.log("DB"); } }

function executeLog(logger) {
  // JS does not care about the class type.
  // It only checks whether the method exists at runtime.
  if (typeof logger.log === 'function') {
    logger.log();
  } else {
    throw new Error("Invalid logger format");
  }
}
```

---

## The interview answers

### What happens under the hood with `class` and `extends`?

"In JavaScript, `class` is syntactic sugar over constructor functions and prototypal inheritance. There are no actual classes like in Java.

When I define a class and methods, the engine converts the class into a standard function and attaches the methods to that function's `.prototype` object. When I use `extends`, the engine wires up the `[[Prototype]]` chain. It does two things. First, it sets the child's `.prototype` to an object created from the parent's `.prototype` via `Object.create()`, which lets instances inherit methods. Second, it uses `Object.setPrototypeOf()` to link the child constructor function itself to the parent constructor function, which lets the child inherit static methods.

TypeScript handles this depending on the compilation target. Targeting modern ES6 or above, it leaves `class` and `extends` exactly as they are. Compiling down to ES5, it generates a helper usually called `__extends`, which mimics the modern behaviour by copying static properties over and reassigning the prototype chain using `Object.create()`. Both end up using standard prototype object delegation."

### Why is TypeScript's `private` fake encapsulation?

"TypeScript's `private` and `protected` are strictly compile time constraints. They provide developer tooling, type safety, and catch structural errors in the IDE before the code runs. But during compilation the compiler strips them away, and in the output JavaScript those properties are emitted as standard public object properties. If someone logs the object at runtime or iterates it with `Object.keys()`, that data is fully exposed.

Modern JavaScript introduced the `#` prefix for truly private fields. That is not stripped, it is natively understood by the engine, which stores those fields in internal slots associated with the object. Accessing a `#` field from outside its class scope at runtime throws a syntax error.

So for truly sensitive backend data, such as API secrets or cryptographic keys, native `#` fields provide actual runtime security. TypeScript's modifiers only provide developer experience, not real protection at runtime."
