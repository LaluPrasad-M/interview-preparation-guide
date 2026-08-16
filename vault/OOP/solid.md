# SOLID Principles

> [!tldr]
> The five rules for writing maintainable code. Each one has a canonical bad example that shows up in interviews.

---

## S: single responsibility

> A class should have one, and only one, reason to change.

**Bad.** An `Order` class that calculates taxes, charges a credit card, and sends an email.

**Good.** `OrderService` orchestrates, `TaxCalculator` does the maths, `PaymentService` handles money, `NotificationService` sends email.

---

## O: open closed

> Software entities should be open for extension, but closed for modification.

**Bad.** A giant `switch(type)` statement inside your payment processor. Adding crypto means modifying existing, tested code.

**Good.** Create a new `CryptoPayment` class that implements `IPayment`. The core system accepts it without modification.

---

## L: Liskov substitution

> A child class must be able to completely substitute its parent without breaking the system.

**Bad.** `CashPayment` extends `Payment` but overrides `.refund()` to throw "cannot refund cash online". That breaks the expectation set by the parent.

**Good.** Create separate interfaces such as `IRefundable`.

---

## I: interface segregation

> Clients should not be forced to depend on methods they do not use.

**Bad.** `interface IMachine { print(); fax(); scan(); }`. A basic printer should not be forced to implement `fax()`.

**Good.** `IPrinter`, `IFax`, `IScanner`. Do not create massive god interfaces.

---

## D: dependency inversion

> High level modules should not depend on low level modules. Both should depend on abstractions.

**Bad, tight coupling.** `this.payment = new CardPayment();` inside the `Checkout` class.

**Good, dependency injection.** `constructor(private payment: IPayment)` passed in from the outside.

See [[abstraction-and-dependency-injection]] for why this works at runtime.
