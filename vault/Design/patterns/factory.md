# Factory Pattern

> [!tldr]
> Strategy creates verbs, factory creates nouns. It centralises the `new` keyword so the client never touches concrete classes.

---

## The problem

> [!tip] The trigger
> The logic to instantiate objects is scattered, complex, or requires conditional checks.

---

## The solution

Centralise object creation in a factory class.

**When to use.** When object creation involves complex rules, or when you want to decouple the client from concrete classes.

---

## The simple static factory

```js
class PaymentFactory {
    static createPayment(type) {
        switch (type.toUpperCase()) {
            case "CARD": return new CardPayment();
            case "UPI": return new UpiPayment();
            default: throw new Error("Unsupported payment type");
        }
    }
}
const payment = PaymentFactory.createPayment("UPI");
```

---

## The factory method pattern

The factory method pattern is a creational pattern that provides an interface for creating objects in a superclass, but lets subclasses alter the type of objects created.

### 1. Define the product interface

This is the contract that all notification types must follow. Any code working with notifications depends only on this interface.

```ts
interface Notification {
    send(message: string): void;
}
```

### 2. Define concrete products

```ts
class EmailNotification implements Notification {
    send(message: string): void {
        console.log(`Sending email: ${message}`);
    }
}

class SMSNotification implements Notification {
    send(message: string): void {
        console.log(`Sending SMS: ${message}`);
    }
}

class PushNotification implements Notification {
    send(message: string): void {
        console.log(`Sending push notification: ${message}`);
    }
}

class SlackNotification implements Notification {
    send(message: string): void {
        console.log(`Sending Slack message: ${message}`);
    }
}
```

### 3. Define an abstract creator

This is an abstract class that declares the factory method `createNotification()`, and optionally includes shared behaviour like `send()`, which defines the high level logic using whatever object `createNotification()` provides.

```ts
abstract class NotificationCreator {
    // Factory method, subclasses decide what to create
    abstract createNotification(): Notification;

    // Shared logic that uses the factory method
    send(message: string): void {
        const notification = this.createNotification();
        notification.send(message);
    }
}
```

Think of this class as a template. It does not know what notification it is sending, but it knows how to send it, and it defers the choice of type to its subclasses.

> [!tip] The one line
> The abstract creator defines the flow, not the details.

### 4. Define concrete creators

Each concrete creator extends the abstract creator and overrides the factory method to return its specific product.

`EmailNotificationCreator` returns `new EmailNotification()`. `SMSNotificationCreator` returns `new SMSNotification()`.

No more conditionals. Each class knows what it needs to create. The mapping is one to one and explicit, and the core system does not need to care.
