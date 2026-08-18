# Observer Pattern

> [!tldr]
> Pub/sub in one class. One thing changes, many unrelated things react, and nobody is coupled to anybody.

---

## The problem

> [!tip] The trigger
> When one part of your system changes, multiple other unrelated systems need to react, but you do not want tight coupling.

---

## The solution

A publisher and subscriber model. An object maintains a list of dependents and notifies them of state changes.

**When to use.** Event handling, reactivity, webhooks, mimicking Kafka or RabbitMQ locally.

---

## The code

```ts
type ObserverFn = (data: any) => void;

class EventEmitter {
    private events: Map<string, ObserverFn[]> = new Map();

    subscribe(event: string, fn: ObserverFn) {
        if (!this.events.has(event)) this.events.set(event, []);
        this.events.get(event)!.push(fn);
    }

    emit(event: string, data: any) {
        const listeners = this.events.get(event) || [];
        listeners.forEach(fn => fn(data));
    }
}
```

---

## The hard part in a machine coding round

`unsubscribe`. Return an object with a `release()` method from the subscribe function, so the user can cancel it in constant time rather than scanning the array.
