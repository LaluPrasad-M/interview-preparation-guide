# Advanced Singleton Examples

> [!tldr]
> A worked connection pool demonstrates singleton patterns at scale with concurrency and resource management.

Part of [[singleton]].

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

**Pros.** It ensures a single instance and provides a global access point. Only one object is created, which helps for resource heavy classes. It provides a way to maintain global state. It supports lazy loading. It guarantees every object in the application uses the same global resource.

**Cons.** It violates single responsibility, because the pattern solves two problems at once. In multithreaded environments, special care is needed to avoid race conditions. It introduces global state, which can be hard to manage. Classes using the singleton become tightly coupled to it. It makes unit testing difficult because of that global state.
