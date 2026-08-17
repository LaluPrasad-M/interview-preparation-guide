# The Four Pillars

> [!tldr]
> Encapsulation hides state, abstraction hides mechanics, inheritance reuses structure, polymorphism swaps behaviour.

---

## Encapsulation

Encapsulation hides internal state and exposes only controlled access through methods, which protects the integrity of the data.

> [!tip] Interview line
> Encapsulation ensures controlled access to data and improves security by preventing external mutations.

**JavaScript** uses `#` for true runtime privacy. **TypeScript** uses `private` or `protected`, but TS `private` compiles to public JS, so it is a developer tooling guard, not a runtime guard.

```ts
// TypeScript approach, compile time
// Using #private in TypeScript is a good choice when you specifically
// want runtime enforced private fields.
class TSPayment {
    constructor(private amount: number, private status: string = "INITIATED") {}

    public getStatus(): string { return this.status; }
}

// JavaScript approach, runtime
class JSPayment {
    #amount;
    #status; // true private fields

    constructor(amount) {
        this.#amount = amount;
        this.#status = "INITIATED";
    }

    getStatus() { return this.#status; }
}
```

---

## Abstraction

Abstraction hides implementation details and exposes only what the outside world needs. It defines what an object does, not how it does it.

> [!tip] Interview line
> Abstraction reduces system complexity by exposing only essential operations and hiding the internal mechanics.

**JavaScript** has no native `interface` or `abstract` keyword, so we simulate it by throwing errors in base classes. **TypeScript** has native `interface` and `abstract class` support.

```ts
// TypeScript, native interfaces
interface IPayment {
    process(): void;
}
class TSCardPayment implements IPayment {
    process() { console.log("Processing via TS Interface"); }
}

// JavaScript, simulated abstraction
class JSPaymentBase {
    process() { throw new Error("Method 'process()' must be implemented."); }
}
class JSCardPayment extends JSPaymentBase {
    process() { console.log("Processing via JS Override"); }
}
```

See [[abstraction-and-dependency-injection]] for how abstraction, DI and polymorphism connect.

---

## Inheritance

A child class derives properties and behaviours from a parent class. It enables code reuse, but creates tight coupling. It models the is-a relationship.

> [!tip] Interview line
> Inheritance helps reuse common logic and enforce a shared structure, though we should prefer composition where possible.

```ts
class Payment {
    constructor(public id: string) {}
    logTransaction() { console.log(`Logged ${this.id}`); }
}

class PayPalPayment extends Payment {
    constructor(id: string, public email: string) {
        super(id); // must call super() before accessing 'this'
    }
}
```

---

## Polymorphism

Polymorphism means many forms: the ability to call the same method on different objects and have each one respond in its own way.

> [!tip] Interview line
> Polymorphism enables flexible and dynamic behaviour by allowing interchangeable objects to respond to the same method call.

```ts
// The caller does not need to know whether this is a card or a PayPal payment.
// It just calls .process() and trusts the object to handle its own behaviour.
function checkout(paymentMethod: IPayment) {
    paymentMethod.process();
}
```

---

## Abstract methods, since they come up here

An abstract method has no implementation.

```ts
abstract class Shape {
    abstract area(): number;
}
```

Every subclass must implement it.

```ts
class Circle extends Shape {
    constructor(private radius: number) {
        super();
    }

    area(): number {
        return Math.PI * this.radius * this.radius;
    }
}
```

**Why use it?** Suppose every payment method must support `pay()`, but each type implements it differently.

```ts
abstract class Payment {
    abstract pay(amount: number): void;

    printReceipt() {
        console.log("Receipt generated");
    }
}

class CreditCardPayment extends Payment {
    pay(amount: number) {
        console.log(`Paid ${amount} using Credit Card`);
    }
}

class UpiPayment extends Payment {
    pay(amount: number) {
        console.log(`Paid ${amount} using UPI`);
    }
}
```

Now every payment must implement `pay()`, and automatically gets `printReceipt()`.
