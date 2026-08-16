# Distributed ID Generation

> [!tldr]
> A 64 bit Snowflake ID, with PostgreSQL leasing the 10 bit machine IDs. The whole design exists because auto increment locks and UUIDv4 destroys B-tree indexes.

---

## The problem

Every distributed system needs unique IDs for users and orders.

A single PostgreSQL `AUTO_INCREMENT` table will lock and crash if you ask it for 100,000 IDs per second.

`UUIDv4` strings are 128 bit random characters. Inserting massive random strings into a relational database destroys B-tree indexes through write amplification, because the database constantly re sorts the index tree.

**The objective.** Build a decentralised REST API generating billions of IDs per second. The IDs must be 64 bit integers, so they fit standard `BIGINT` columns, and time sortable, so database indexes stay balanced.

---

## Functional requirements

Generate a universally unique ID on demand. The ID must strictly be a 64 bit integer. Because REST has HTTP overhead, the API must allow clients to request a batch, for example `count=100`, in a single network call.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | extreme, target above 100,000 IDs per second globally |
| Performance | generation logic under 1 millisecond, network adds 2 to 5 ms for the HTTP call |
| Availability against consistency | availability is prioritised, because if the ID generator is down the entire company halts |
| Concurrency | completely thread safe, two parallel requests hitting the same server in the same millisecond must get different IDs |
| Edge cases | clock drift from NTP moving clocks backward, and JavaScript's 53 bit float limit |

---

## The 64 bit ID structure

```text
  [ 1 Bit ] [      41 Bits      ] [    10 Bits    ] [      12 Bits      ]
  Sign Bit      Timestamp (ms)      Machine/Node ID   Sequence Counter
  (Always 0)   (69 years of IDs)    (Max 1024 Nodes)  (Max 4096 IDs / ms)
```

---

## The architecture

```text
      +-------------------------------------------+
      |         CLIENT APP / MICROSERVICE         |
      |    (e.g., Order Service needing an ID)    |
      +---------------------+---------------------+
                            | 1. Sync HTTPS (REST)
                            | GET /v1/ids?count=50
                            v
      +-------------------------------------------+
      |             INTERNAL LOAD BALANCER        |
      |    (Round-Robin routes to a random node)  |
      +---------------------+---------------------+
                            | 2. Routes request
                            v
  +--------------------------------------------------------------+
  |                   ID GENERATOR FLEET                         |
  |   (Stateless, horizontally scaled Node.js pods)              |
  +----------------------+----------------------+----------------+
  |    Generator Node 1  |    Generator Node 2  | Generator Node N
  |    [Holds ID: 01]    |    [Holds ID: 02]    | [Holds ID: N]
  +---------+------------+----------+-----------+--------+-------+
            |                       |                    |
            | 3. Sync TCP (on boot and heartbeat)        |
            v                       v                    v
      +---------------------------------------------------+
      |               POSTGRESQL CLUSTER                  |
      |   (Maintains leases for the 10-bit Machine IDs)   |
      +---------------------------------------------------+
```

---

## How the machine ID works

### Part A: how the server gets its machine ID

When a new server boots it has `let myMachineId = null;`. Before it accepts HTTP traffic, it connects to PostgreSQL to lease an ID, using `SKIP LOCKED`.

```sql
BEGIN;
-- Find an available ID (0 to 1023), lock it, and skip rows other booting pods hold
SELECT machine_id FROM machine_id_leases
WHERE status = 'AVAILABLE' OR last_heartbeat < NOW() - INTERVAL '30 seconds'
LIMIT 1 FOR UPDATE SKIP LOCKED;

-- Say it returned 5. Claim it.
UPDATE machine_id_leases
SET status = 'IN_USE', ip_address = '10.0.5.99', last_heartbeat = NOW()
WHERE machine_id = 5;
COMMIT;
```

The server now stores `myMachineId = 5` in local RAM, and runs a background `setInterval` updating `last_heartbeat` in Postgres every 10 seconds so it does not lose the lease.

### Part B: the bitwise maths

When a request lands on node 5, it uses bitwise left shifts.

> [!warning] The Node.js detail
> Standard bitwise operators only work on 32 bit integers. To do 64 bit maths in Node.js you must use `BigInt`.

```js
// 1. Get current time in ms
const currentTimestamp = BigInt(Date.now() - CUSTOM_EPOCH);

// 2. Shift the timestamp left by 22 bits (10 for machine + 12 for sequence)
const timeBits = currentTimestamp << 22n;

// 3. Shift the machine ID (5) left by 12 bits
const machineBits = BigInt(myMachineId) << 12n;

// 4. Take the sequence, for example the 3rd request this millisecond
const sequenceBits = BigInt(currentSequence);

// 5. Bitwise OR them into one 64-bit integer
const finalId = timeBits | machineBits | sequenceBits;

return finalId.toString(); // e.g., "1234567890123456789"
```

That runs entirely in RAM, with zero database calls.

---

## API design

Because we use REST instead of gRPC, HTTP connection overhead is our biggest enemy. We must support batching, and clients must use HTTP keep alive connections.

**Endpoint.** `GET /v1/ids`

**Query parameters.** `count=50`, optional, defaults to 1, max 1000 to prevent hogging a single millisecond.

**Response, 200 OK.**

```json
{
  "meta": {
    "generator_node_id": 5,
    "generated_count": 50,
    "latency_ms": 0.1
  },
  "data": {
     "ids": [
       "16912345678905000",
       "16912345678905001"
     ]
  }
}
```

The IDs must be an array of strings, not numbers. See the serialisation trap below.

---

## Database design, the coordination layer

**Table `machine_id_leases`.**

| Column | Type | Holds |
| --- | --- | --- |
| `machine_id` | SMALLINT, primary key | pre populated with 0 through 1023 |
| `ip_address` | VARCHAR | the IP of the pod currently holding it |
| `status` | VARCHAR | `AVAILABLE` or `IN_USE` |
| `last_heartbeat` | TIMESTAMP WITH TIME ZONE | for lease expiry |

```sql
CREATE INDEX idx_available_machines ON machine_id_leases(status, last_heartbeat);
```

---

## Trade offs and edge cases

### REST against gRPC for internal IDs

gRPC uses HTTP/2 multiplexing, so thousands of ID requests travel over a single TCP connection concurrently. REST uses HTTP/1.1, which requires opening new connections or waiting in line.

We consciously traded raw network speed for architectural simplicity and easier debugging. To mitigate the REST bottleneck, we force microservices to ask for batches, `?count=50`, and keep them in local memory, minimising network calls.

### The JavaScript 53 bit serialisation trap

**The trap.** A 64 bit integer goes up to `9,223,372,036,854,775,807`. JavaScript's `Number` type, an IEEE 754 float, maxes out at `9,007,199,254,740,991`. If you send a raw 64 bit JSON number to a React frontend or a Node.js microservice, `JSON.parse()` silently rounds the last three digits to `000`, corrupting your primary keys.

**The fix.** The REST API must always call `.toString()` on the `BigInt` before putting it into the JSON response.

---

## Follow up questions

### The clock moved backwards

**Q.** Snowflake relies on the server's system clock. What happens if NTP syncs the clock and it accidentally moves backwards by 2 seconds?

**A.** This is the most dangerous edge case, because it causes duplicate IDs. The service keeps `last_timestamp` in memory. Before generating an ID it checks `if (current_timestamp < last_timestamp)`. If true, the clock moved backward, and the worker immediately returns HTTP 503 for that request. The client microservice sees the 503 and its HTTP client retries, routing to a different healthy node. Our node pauses until the clock catches back up.

### The sequence overflows

**Q.** What if node 5 receives 10,000 requests in exactly 1 millisecond? The sequence is only 12 bits, so it maxes out at 4096 IDs per millisecond.

**A.** Once the sequence counter hits 4096, node 5 has exhausted its ID space for that millisecond. The algorithm implements a busy wait: a tiny `while (current_timestamp <= last_timestamp)` loop. This pauses the thread for a fraction of a millisecond until the clock rolls over, at which point the sequence resets to 0 and generation safely resumes.

### ZooKeeper instead of PostgreSQL

**Q.** If we used ZooKeeper for leasing machine IDs, how would the architecture differ?

**A.** Instead of `SKIP LOCKED` queries with 10 second heartbeats, the server opens a persistent TCP session with a ZooKeeper cluster and creates an ephemeral znode, for example `/snowflake/workers/node_05`. ZooKeeper inherently guarantees uniqueness. If the pod crashes, the TCP connection drops, ZooKeeper deletes the znode, and machine ID 5 is instantly freed for a new pod.

ZooKeeper is elegant and faster at detecting crashes than Postgres polling, but it introduces a heavy JVM based infrastructure component to maintain, which is why modern systems often prefer Postgres or Redis.
