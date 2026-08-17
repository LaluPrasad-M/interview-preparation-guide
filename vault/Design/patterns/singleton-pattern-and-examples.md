# Singleton Pattern and Basic Examples

> [!tldr]
> Hide the constructor, expose a static `getInstance()`. In JavaScript and TypeScript, an ES module export is the better answer.

Part of [[singleton]].

---

## The problem

You need exactly one instance of a class across the entire application.

**When to use.** Database connections, loggers, config managers.

---

## Lazy initialisation, created when asked for

```ts
class LazySingleton {
    // Holds the single shared instance (initially not created)
    private static instance: LazySingleton;

    // Private constructor prevents creating objects from outside the class
    private constructor() {}

    // Global access point to get the singleton instance
    public static getInstance(): LazySingleton {

        // Create the instance only when first requested
        if (LazySingleton.instance == null) {
            LazySingleton.instance = new LazySingleton();
        }

        return LazySingleton.instance;
    }
}
```

> [!warning] Not thread safe
> This implementation is not thread safe. If multiple threads call `getInstance()` simultaneously while `instance` is still null, it is possible to create multiple instances.
>
> In Node this is only a real risk across worker threads, since ordinary async code cannot interleave inside the null check. See [[private-static-and-locks]].

---

## Eager initialisation

The instance is created as soon as the class or module is loaded, before any thread can access it. That makes it inherently thread safe without explicit locks, because initialisation happens once during load.

This is suitable if your application always creates and uses the singleton, or if the overhead of creating it is minimal.

```ts
class EagerSingleton {
    // Created immediately when the class is evaluated
    private static readonly instance: EagerSingleton = new EagerSingleton();

    private constructor() {}

    public static getInstance(): EagerSingleton {
        return EagerSingleton.instance;
    }
}
```

---

## The ES module singleton, recommended

In TypeScript and JavaScript, ES modules are evaluated once and cached. Exporting an instance from a module makes it a natural singleton.

```ts
// logger.ts
class Logger {
    private logs: string[] = [];

    log(message: string): void {
        const timestamp = new Date().toISOString();
        const entry = `[${timestamp}] ${message}`;
        this.logs.push(entry);
        console.log(entry);
    }

    getLogs(): string[] {
        return [...this.logs];
    }
}

// Single instance, created when the module is first imported
export const logger = new Logger();

// Usage from other files:
// import { logger } from './logger';
// logger.log("Server started");
```

---

## A worked cache manager

```ts
// cache-manager.ts
class CacheManager {
    private cache = new Map<string, { value: string; expiry: number | null }>();

    put(key: string, value: string, ttlSeconds: number = 0): void {
        const expiry = ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : null;
        this.cache.set(key, { value, expiry });
    }

    get(key: string): string | null {
        const entry = this.cache.get(key);
        if (!entry) return null;
        if (entry.expiry !== null && Date.now() > entry.expiry) {
            this.cache.delete(key);
            return null;
        }
        return entry.value;
    }

    remove(key: string): void {
        this.cache.delete(key);
    }

    size(): number {
        const now = Date.now();
        for (const [key, entry] of this.cache) {
            if (entry.expiry !== null && now > entry.expiry) {
                this.cache.delete(key);
            }
        }
        return this.cache.size;
    }
}

export const cacheManager = new CacheManager();

const cache1 = cacheManager;
const cache2 = cacheManager;

console.log(`Same instance? ${cache1 === cache2}`); // true

cache1.put("user:42", "{name: 'Alice'}", 5); // 5 second TTL
cache1.put("config:theme", "dark");          // no expiry

console.log(`user:42 = ${cache2.get("user:42")}`);           // {name: 'Alice'}
console.log(`config:theme = ${cache2.get("config:theme")}`); // dark
console.log(`Cache size: ${cache2.size()}`);                 // 2
```

---

## A minimal counter

```ts
class Counter {
    private static instance: Counter;
    private count: number = 0;

    private constructor() {}

    static getInstance(): Counter {
        if (!Counter.instance) {
            Counter.instance = new Counter();
        }
        return Counter.instance;
    }

    increment(): void {
        this.count++;
    }

    getCount(): number {
        return this.count;
    }
}

const c1 = Counter.getInstance();
const c2 = Counter.getInstance();
console.log("Same instance:", c1 === c2);
for (let i = 0; i < 5; i++) {
    c1.increment();
}
console.log("Count after 5 increments:", c1.getCount());
```

> [!question] Why is `count` an instance field, and why are `increment` and `getCount` not static?
> The singleton already guarantees exactly one object exists, so instance state is single by construction. Keeping the members on the instance means the class stays an ordinary object that can be injected, mocked or swapped later, rather than a bag of globals.
