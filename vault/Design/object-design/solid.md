# SOLID Principles

> [!tldr]
> The five rules for writing maintainable code. Each one has a canonical bad example that shows up in interviews.

---

## S: single responsibility

> A class should have one, and only one, reason to change.

**Bad.** An `Order` class that calculates taxes, charges a credit card, and sends an email.

**Good.** `OrderService` orchestrates, `TaxCalculator` does the maths, `PaymentService` handles money, `NotificationService` sends email.

> [!tip] The quick check
> If you can only describe a class using "and", it likely violates SRP. "Calculates tax and charges a card and sends an email" is the smell itself.

---

## O: open closed

> Software entities should be open for extension, but closed for modification.

**Bad.** A giant `switch(type)` statement inside your payment processor. Adding crypto means modifying existing, tested code.

**Good.** Create a new `CryptoPayment` class that implements `IPayment`. The core system accepts it without modification.

> [!tip] Interview line
> New payment type, zero changes to existing, tested code. That is what "closed for modification" buys you.

---

## L: Liskov substitution

> A child class must be able to completely substitute its parent without breaking the system.

**Bad.** `CashPayment` extends `Payment` but overrides `.refund()` to throw "cannot refund cash online". That breaks the expectation set by the parent.

**Good.** Create separate interfaces such as `IRefundable`.

> [!tip] Interview line
> If a subclass has to throw "not supported" inside a method the parent promises, that is an LSP violation, not an edge case.

---

## I: interface segregation

> Clients should not be forced to depend on methods they do not use.

**Bad.** `interface IMachine { print(); fax(); scan(); }`. A basic printer should not be forced to implement `fax()`.

**Good.** `IPrinter`, `IFax`, `IScanner`. Do not create massive god interfaces.

> [!tip] Interview line
> A class implementing methods it throws `NotImplementedError` from is the tell. Split the interface instead of stubbing it.

---

## D: dependency inversion

> High level modules should not depend on low level modules. Both should depend on abstractions.

**Bad, tight coupling.** `this.payment = new CardPayment();` inside the `Checkout` class.

**Good, dependency injection.** `constructor(private payment: IPayment)` passed in from the outside.

See [[abstraction-and-dependency-injection]] for why this works at runtime.

### Why it is called "inversion"

Without DI, the high level `Checkout` class decides which low level class to create, so control over the dependency flows from high level to low level. `Checkout` depends directly on `CardPayment`.

With DI, that direction flips. `Checkout` no longer decides which implementation it gets, something outside it does, and `Checkout` only depends on the `IPayment` shape. Control over which concrete class gets used is inverted, from the high level module deciding, to something external deciding. That is the "inversion" in dependency inversion.

---

## What each one prevents

| Principle | Prevents |
| --- | --- |
| SRP | one change forcing edits across unrelated logic |
| OCP | breaking tested code every time a new variant is added |
| LSP | a subclass silently breaking the contract callers rely on |
| ISP | classes implementing methods they do not need or cannot support |
| DIP | high level logic locked to one specific low level implementation |
