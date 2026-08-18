# Strategy Pattern

> [!tldr]
> The highest return pattern in interviews. It swaps behaviour, the verbs, at runtime, and it is what kills your `if/else` chains.

---

## The problem

> [!tip] The trigger
> You have massive `if/else` logic dictating behaviour.

---

## The solution

Extract algorithms into separate classes that implement the same interface. This swaps behaviour dynamically at runtime.

**When to use.** Payment methods, pricing and discount algorithms, routing logic.

---

## The code

```ts
interface IPaymentStrategy {
    pay(amount: number): void;
}

class CardStrategy implements IPaymentStrategy {
    pay(amount: number) { console.log(`Paid ${amount} via Card`); }
}
class UPIStrategy implements IPaymentStrategy {
    pay(amount: number) { console.log(`Paid ${amount} via UPI`); }
}

// The context class uses the strategy, but does not implement it.
class CheckoutContext {
    private strategy: IPaymentStrategy;

    setStrategy(strategy: IPaymentStrategy) {
        this.strategy = strategy;
    }

    executePayment(amount: number) {
        this.strategy.pay(amount); // polymorphism in action
    }
}
```

---

## Why it satisfies open closed

Adding a new payment method means adding a new class. You never modify `CheckoutContext`. See [[solid]].
