# Singleton Pattern

> [!tldr]
> Hide the constructor, expose a static `getInstance()`. In JavaScript and TypeScript, an ES module export is usually the better answer.

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

---

## Worked example: a DB connection pool

Creating a database connection is expensive, so we create a fixed number at startup and reuse them.

The requirements: the pool must be a singleton, it initialises with a maximum of 3 connections, `acquire()` returns a connection if one is available and `null` if the pool is empty, `release(connection)` returns a used connection to the pool, and `getAvailableCount()` returns the number of idle connections.

```ts
class DatabaseConnection {
    constructor(public id: number) { }

    query(sql: string) {
        // Mock query execution
    }
}

class ConnectionPool {
    private static instance: ConnectionPool;

    private availableConnections: DatabaseConnection[] = [];
    private readonly MAX_CONNECTIONS = 3;

    private constructor() {
        for (let i = 1; i <= this.MAX_CONNECTIONS; i++) {
            this.availableConnections.push(new DatabaseConnection(i));
        }
    }

    public static getInstance(): ConnectionPool {
        if (!ConnectionPool.instance) {
            ConnectionPool.instance = new ConnectionPool();
        }
        return ConnectionPool.instance;
    }

    public acquire(): DatabaseConnection | null {
        if (this.availableConnections.length > 0) {
            return this.availableConnections.pop() || null;
        }
        return null;
    }

    public release(connection: DatabaseConnection): void {
        // Guard against exceeding max size and against duplicates
        if (this.availableConnections.length < this.MAX_CONNECTIONS &&
            !this.availableConnections.some(conn => conn.id === connection.id)) {
            this.availableConnections.push(connection);
        }
    }

    public getAvailableCount(): number {
        return this.availableConnections.length;
    }
}
```

### The test suite

This is the harness you would actually type in the round.

```ts
function runTests() {
    let passed = 0;
    let failed = 0;

    function assertEqual(testName: string, actual: any, expected: any) {
        if (actual === expected) {
            console.log(`PASS ${testName}`);
            passed++;
        } else {
            console.error(`FAIL ${testName}. Expected ${expected}, got ${actual}`);
            failed++;
        }
    }

    function assertNotNull(testName: string, actual: any) {
        if (actual !== null && actual !== undefined) {
            console.log(`PASS ${testName}`);
            passed++;
        } else {
            console.error(`FAIL ${testName}. Expected a value, got ${actual}`);
            failed++;
        }
    }

    console.log("--- Running Tests ---");

    try {
        // Test 1: singleton verification
        const pool1 = ConnectionPool.getInstance();
        const pool2 = ConnectionPool.getInstance();
        assertEqual("Test 1: Pool should be a Singleton", pool1 === pool2, true);

        // Test 2: initial pool size
        assertEqual("Test 2: Initial pool should have 3 connections", pool1.getAvailableCount(), 3);

        // Test 3: acquire a connection
        const conn1 = pool1.acquire();
        assertNotNull("Test 3: Should acquire first connection", conn1);
        assertEqual("Test 4: Available count should decrease to 2", pool1.getAvailableCount(), 2);

        // Test 4: exhaust the pool
        const conn2 = pool1.acquire();
        const conn3 = pool1.acquire();
        assertEqual("Test 5: Available count should be 0 after taking 3", pool1.getAvailableCount(), 0);

        // Test 5: acquire from an empty pool
        const conn4 = pool1.acquire();
        assertEqual("Test 6: Should return null when pool is empty", conn4, null);

        // Test 6: release and re-acquire
        if (conn1) {
            pool1.release(conn1);
            assertEqual("Test 7: Available count should be 1 after releasing", pool1.getAvailableCount(), 1);

            const conn5 = pool1.acquire();
            assertNotNull("Test 8: Should acquire a connection after it was released", conn5);
            assertEqual("Test 9: Re-acquired connection should be the one released", conn5?.id, conn1.id);
        } else {
            console.error("Tests 7-9 skipped because conn1 was null");
            failed += 3;
        }

    } catch (e) {
        console.error("Test execution crashed: ", e);
    }

    console.log("---------------------");
    console.log(`Tests Passed: ${passed}`);
    console.log(`Tests Failed: ${failed}`);
}

runTests();
```

---

## Pros and cons

**Pros.** Ensures a single instance and provides a global access point. Only one object is created, which helps for resource heavy classes. Provides a way to maintain global state. Supports lazy loading. Guarantees every object in the application uses the same global resource.

**Cons.** Violates single responsibility, because the pattern solves two problems at once. In multithreaded environments, special care is needed to avoid race conditions. Introduces global state, which can be hard to manage. Classes using the singleton become tightly coupled to it. It makes unit testing difficult because of that global state.
