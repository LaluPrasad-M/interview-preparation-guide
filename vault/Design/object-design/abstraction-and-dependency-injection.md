# Abstraction, Dependency Injection and Polymorphism

> [!tldr]
> The composition layer knows which implementation it is using. The consumer does not. That separation is the whole point.

---

## Abstraction against encapsulation

**Abstraction.** Expose only the relevant contract. Do not require the consumer to know implementation details.

**Encapsulation.** Restrict direct access to an object's internal state and implementation.

---

## What abstraction actually hides

```ts
interface Payment {
    process(): void;
}

class StripePayment implements Payment {
    process() {
        // 50 lines of Stripe specific logic
    }
}

function checkout(payment: Payment) {
    payment.process();
}
```

The caller knows that `Payment` has `process()`. It does not need to know about the Stripe API, authentication, HTTP calls, retry logic or serialisation.

Notice something subtle: the implementation is not necessarily hidden from the developer. You can open the source and look at it. What is hidden is the implementation detail that the consumer no longer needs to know about or depend on.

---

## The question this raises

If we inject the dependency, do we not already know what we are dealing with?

The answer is that the caller usually does not identify the concrete implementation at all.

---

## Who decides which implementation

Something outside `checkout()` decides.

```ts
const payment = new StripePayment();
checkout(payment);
```

Here the composition root knows we are using Stripe. But `checkout()` does not.

```text
                 Composition Root
                       |
               "Use Stripe today"
                       |
                       v
              StripePayment
                       |
                       v
                 Payment interface
                       |
                       v
                  checkout()
                       |
                       v
                  payment.process()
```

The business logic does not care.

---

## Choosing dynamically with a factory

Suppose the request says `{ "paymentMethod": "upi" }`. Your controller or factory selects the implementation.

```ts
function createPayment(method: string): Payment {
    switch (method) {
        case "stripe":
            return new StripePayment();

        case "upi":
            return new UpiPayment();

        default:
            throw new Error("Unsupported payment method");
    }
}

const payment = createPayment(req.body.paymentMethod);
checkout(payment);
```

```text
Request
  |
  | "upi"
  v
Factory
  |
  |-- StripePayment
  +-- UpiPayment
           |
           v
       Payment
           |
           v
       checkout()
```

`checkout()` still does not know which one it got.

---

## Where dependency injection fits

DI simply says: do not make `checkout()` create the dependency itself. Give it the dependency instead.

**Bad, tightly coupled to Stripe.**

```ts
function checkout() {
    const payment = new StripePayment();
    payment.process();
}
```

**Better.**

```ts
function checkout(payment: Payment) {
    payment.process();
}

const payment = createPayment("stripe");
checkout(payment);
```

That is dependency injection.

---

## How the runtime knows which `process()` to run

This is polymorphism, or dynamic dispatch.

```ts
const payment: Payment = new StripePayment();
payment.process();
```

The variable is typed as `Payment`, but the actual object is `StripePayment`. At runtime, JavaScript looks at the actual object and invokes its implementation.

```text
payment
  |
  v
actual object = StripePayment
  |
  v
StripePayment.process()
```

If instead the object is a `UpiPayment`, `UpiPayment.process()` runs. You never need `if (payment instanceof StripePayment)`. That is the whole point of polymorphism.

---

## How the three fit together

```text
Abstraction
"What can this dependency do?"
          |
DI
"Here is an implementation that satisfies that contract."
          |
Polymorphism
"Call the implementation appropriate to the actual object."
```

Without abstraction, `checkout(stripePayment)` means your business logic understands Stripe. With abstraction, `checkout(payment: Payment)` means your business logic understands the capability, not the implementation.

DI supplies the implementation. Polymorphism decides which implementation's method executes.

Once you see this, factory, DI, interface and polymorphism stop looking like four unrelated OOP concepts and start looking like pieces of the same puzzle.
