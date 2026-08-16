# SOLID: JavaScript against TypeScript

> [!tldr]
> Every SOLID principle survives in plain JavaScript. TypeScript uses interfaces as the contract, JavaScript uses duck typing and the prototype chain.

The principles themselves, with their bad and good examples, are in [[solid]]. This note is what each one looks like in code in both languages, and what the compiler is doing for you.

---

## Single responsibility

The structural implementation is identical in both languages. The difference is that TypeScript stops you accidentally passing the wrong object into a tightly scoped class, whereas JavaScript needs runtime checks or unit tests to know the injected dependencies are valid.

```typescript
// Good: separated responsibilities
class UserAuthenticator {
  login(user: string): boolean { return true; }
}

class EmailService {
  sendWelcomeEmail(user: string): void { console.log("Email sent"); }
}

class AuthController {
  // TS ensures only the exact shapes are injected
  constructor(private auth: UserAuthenticator, private email: EmailService) {}

  handleLogin(user: string) {
    if (this.auth.login(user)) {
      this.email.sendWelcomeEmail(user);
    }
  }
}
```

```javascript
// Good: separated responsibilities. Under the hood, just functions on prototypes.
class UserAuthenticator {
  login(user) { return true; }
}

class EmailService {
  sendWelcomeEmail(user) { console.log("Email sent"); }
}

class AuthController {
  constructor(auth, email) {
    // JS has no compile time checks, so we rely on duck typing.
    // We expect 'auth' to have a 'login' method on its prototype.
    this.auth = auth;
    this.email = email;
  }

  handleLogin(user) {
    this.auth.login(user);
    this.email.sendWelcomeEmail(user);
  }
}
```

---

## Open closed

TypeScript enforces this with interfaces: you extend by creating new classes that implement the interface. JavaScript enforces it via standard polymorphism, expecting objects to have identically named methods.

```typescript
interface PaymentMethod {
  pay(amount: number): void; // the contract
}

class CreditCard implements PaymentMethod {
  pay(amount: number) { console.log(`Paid ${amount} via CC`); }
}

class UPI implements PaymentMethod { // extending via a new class, not modifying an existing one
  pay(amount: number) { console.log(`Paid ${amount} via UPI`); }
}

class Checkout {
  // TS guarantees paymentMethod has a pay() method
  process(paymentMethod: PaymentMethod, amount: number) {
    paymentMethod.pay(amount);
  }
}
```

```javascript
class CreditCard {
  pay(amount) { console.log(`Paid ${amount} via CC`); }
}

class UPI {
  pay(amount) { console.log(`Paid ${amount} via UPI`); }
}

class Checkout {
  process(paymentMethod, amount) {
    // JS looks up the prototype chain at runtime for a method named 'pay'.
    // If we add a new payment method, we do not modify Checkout.
    if (typeof paymentMethod.pay !== 'function') {
      throw new Error("Invalid payment method object");
    }
    paymentMethod.pay(amount);
  }
}
```

---

## Liskov substitution

TypeScript catches violations at compile time, for example a child method returning a `string` where the parent returned an object. JavaScript blindly executes and blows up at runtime when the caller tries to read an object property off a string.

```typescript
class Bird {
  fly(): void { console.log("Flying"); }
}

// LSP violation: a penguin is a bird, but it cannot fly.
// Substituting Penguin where Bird is expected breaks the app logic.
class Penguin extends Bird {
  override fly(): void {
    throw new Error("I cannot fly!"); // breaking the contract
  }
}
```

```javascript
class Database {
  fetch() { return { data: "Valid Data" }; }
}

class BrokenDatabase extends Database {
  // LSP violation: changing the return type unexpectedly
  fetch() { return "Just a string"; }
}

function processData(db) {
  // If BrokenDatabase is passed, the engine walks up the prototype chain,
  // hits the overridden fetch(), returns a string, and crashes here:
  const result = db.fetch();
  console.log(result.data.toUpperCase()); // TypeError: Cannot read properties of undefined
}
```

---

## Interface segregation

This principle is deeply tied to static typing. TypeScript uses the `interface` keyword to enforce it. Because JavaScript has no interfaces, it translates more abstractly to: do not create massive god classes, or massive configuration objects that require passing nulls for unused properties.

```typescript
// Bad: a fat interface
interface Machine {
  print(): void;
  scan(): void;
}

// Good: segregated interfaces
interface Printer { print(): void; }
interface Scanner { scan(): void; }

class BasicPrinter implements Printer {
  print() { console.log("Printing"); }
  // Not forced to implement scan()
}
```

---

## Dependency inversion

TypeScript uses interfaces as the abstraction layer, so high level classes depend on the interface rather than the concrete implementation. JavaScript achieves the same by passing instances into constructors, relying entirely on duck typing rather than a formal contract.

```typescript
interface Logger { log(msg: string): void; } // the abstraction

class SentryLogger implements Logger {
  log(msg: string) { /* Sentry logic */ }
}

class App {
  // App depends on the Logger interface, not on SentryLogger directly.
  constructor(private logger: Logger) {}
}
// The compiler erases the interface, but ensures structural integrity before emitting JS.
```

```javascript
class SentryLogger {
  log(msg) { /* Sentry logic */ }
}

class App {
  // Dependency injection in JS.
  // App does not care whether 'logger' is Sentry, Winston or Console,
  // as long as the prototype chain has a log() method.
  constructor(logger) {
    this.logger = logger;
  }
}
```

---

## The interview answers

### Applying DIP and OCP in plain JavaScript

"Even without TypeScript's `interface` keyword, DIP and OCP apply perfectly to JavaScript through dependency injection and duck typing.

To apply dependency inversion, I ensure my high level business logic modules never instantiate their own low level dependencies, such as database connections or logging libraries, using `new` inside their methods. Instead I inject those dependencies through the constructor.

For example, instead of an `OrderService` creating a `new MySQLConnection()`, it accepts a `dbConnection` argument in its constructor. Because JavaScript relies on duck typing, the `OrderService` does not care what class that actually is. It only cares that at runtime the engine can walk up the object's prototype chain and find a `.query()` method.

That automatically satisfies open closed. If we migrate from MySQL to PostgreSQL, we do not modify `OrderService`, so it is closed for modification. We write a new `PostgresConnection` class that also has a `.query()` method on its prototype and inject that, so it is open for extension. It also makes testing easy, because I can inject mock objects without altering the core service."

### What an LSP violation does structurally

"Liskov substitution says instances of a child class must be perfectly substitutable for the parent without altering the correctness of the program. The child must honour the contract the parent established.

If I violate this in JavaScript, for example a parent `Repository` whose `.findById()` returns an object while a child `CachingRepository` overrides it to return a boolean or a raw string, the application will likely crash. Structurally, the engine resolves method calls by traversing the `[[Prototype]]` chain. It finds the child's overridden method first, executes it, and returns the wrong type. The calling function, expecting an object, tries to read a property off that string and gets a runtime `TypeError: Cannot read properties of undefined`.

TypeScript prevents this at compile time. If I define a parent method with a specific return type or parameter signature, the compiler enforces that any child overriding it adheres to that signature. If the child returns a string where an object is expected, the compiler errors and refuses to emit the JavaScript, catching the violation before production."
