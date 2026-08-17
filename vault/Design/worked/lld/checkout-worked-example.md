# Worked Example: E-Commerce Checkout

> [!tldr]
> Four patterns wired together in one flow. Builder creates the payload, factory picks the payment, strategy runs it, observer notifies everyone else.

---

## What each pattern does here

**Builder.** It creates the complex `Order` payload.

**Factory.** It instantiates the correct payment method.

**Strategy.** It processes the specific payment logic.

**Observer.** It triggers post payment asynchronous actions such as email and analytics.

---

## The code

```ts
// --- 1. The core orchestrator (facade / controller) ---
class CheckoutService {
    // Dependency injection, the DIP principle
    constructor(
        private paymentService: PaymentService,
        private orderService: OrderService,
        private eventEmitter: EventEmitter
    ) {}

    public processCheckout(user: string, items: string[], paymentType: string) {

        // 1. Build the order (BUILDER)
        const order = new OrderBuilder()
            .setUser(user)
            .addItem(items[0])
            .build();

        // 2. Save the order to the DB
        this.orderService.createOrder(order);

        // 3. Create the payment object (FACTORY)
        const paymentStrategy = PaymentFactory.createPayment(paymentType);

        // 4. Process the payment (STRATEGY + POLYMORPHISM)
        this.paymentService.process(paymentStrategy);

        // 5. Emit events to decoupled services (OBSERVER)
        this.eventEmitter.emit("PAYMENT_SUCCESS", order);
    }
}

// --- 2. Post checkout listeners, decoupled via observer ---
function sendConfirmationEmail(order: any) {
    console.log(`Sending email for order to ${order.user}`);
}
function updateAnalytics(order: any) {
    console.log(`Updating analytics for 1 new sale.`);
}

// --- 3. System wiring and execution ---
const emitter = new EventEmitter();
emitter.subscribe("PAYMENT_SUCCESS", sendConfirmationEmail);
emitter.subscribe("PAYMENT_SUCCESS", updateAnalytics);

const checkoutApp = new CheckoutService(
    new PaymentService(),
    new OrderService(),
    emitter
);

// Triggers the entire flow
checkoutApp.processCheckout("Rahul", ["MacBook Pro"], "UPI");
```

---

## The architecture mental model

```text
User -> CheckoutService (Orchestrator)
           |
      OrderBuilder -> (Creates complex payload)
           |
      PaymentFactory -> (Instantiates specific Payment object)
           |
      Payment.process() -> (Strategy executes polymorphic behaviour)
           |
      EventEmitter.emit() -> (Observer notifies downstream systems)
           |
      [EmailService, AnalyticsService] -> (React independently)
```

---

## Pattern mapping, memorise this

| If the problem is            | Use pattern   | Example                               |
| ---------------------------- | ------------- | ------------------------------------- |
| Controlling global access    | [[singleton]] | DB connection pool                    |
| Complex object instantiation | [[factory]]   | creating UI buttons or payment types  |
| Swappable conditional logic  | [[strategy]]  | sorting algorithms, payment providers |
| Asynchronous event handling  | [[observer]]  | post checkout webhooks, UI updates    |
| Step by step construction    | [[builder]]   | order creation, HTTP requests         |

---

## The interview answer script

**Interviewer.** How would you design the checkout system for an e-commerce app?

**You.** "I would build this around SOLID principles, so it stays modular and easy to extend. The builder pattern handles the complexity of putting an order together. For payments, I would use the strategy pattern, so a new payment type can be added later without touching existing code: that is the open closed principle. A factory picks and instantiates the right strategy. For anything that happens after checkout, sending an email, updating analytics, I would use the observer pattern, an event driven design. That keeps `CheckoutService` down to a single responsibility, dependent only on injected abstractions, which is what makes the whole thing easy to test."
