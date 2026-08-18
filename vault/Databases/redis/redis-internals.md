# Redis Internals

> [!tldr]
> Redis is fast because a single thread never contends with itself. That single fact explains most of Redis's guarantees and most of its production failure modes.

---

## Why Redis is fast

Every command runs on one thread, one at a time, to completion. There is no lock contention between commands because there is nothing running concurrently to contend with. Combined with in-memory storage and simple data structures, that single-threaded execution is most of why Redis is fast, not despite being single-threaded but because of it.

> [!warning] Redis 6 added threading, but only for networking
> Reading bytes off the socket and parsing the protocol got threaded in Redis 6. Command execution itself, the part that actually reads or writes your data, is still single-threaded. This is a common trap: "Redis is multi-threaded now" is true and misleading at the same time.

---

## Why MULTI/EXEC is not a SQL transaction

| | SQL transaction | Redis MULTI/EXEC |
| --- | --- | --- |
| Isolation | other transactions can be blocked or wait | nothing else runs anyway, single thread |
| Rollback | a failed statement can roll back the whole transaction | a command that errors does not stop the rest, they all still run |
| Atomicity | all-or-nothing | all commands run, but a runtime error in one does not undo the others |

`MULTI`/`EXEC` guarantees no other client's commands run in between yours, since the thread cannot be interleaved anyway. It does not give you rollback on error. If command 3 of 5 fails at runtime, commands 4 and 5 still execute.

---

## What Lua scripts are actually for

One command is atomic. A sequence of commands with your own logic in the middle is not.

```text
GET inventory        both requests read 1
if inventory > 0     both decide yes
DECR inventory       inventory ends up at -1
```

Two requests read the same value before either wrote, so the shop oversells.
Nothing here is a Redis bug: `GET` was atomic and `DECR` was atomic, the gap between them was not.

A Lua script closes the gap. Redis runs the whole script as one command, so nothing interleaves with it:

```lua
local stock = redis.call("GET", KEYS[1])
if tonumber(stock) > 0 then
  return redis.call("DECR", KEYS[1])
end
return -1
```

The value is not new commands, it is read, decide and write arriving as one unit.
That is why flash sale stock, rate limit counters and lock release all end up as scripts, see [[redis-use-cases]].

---

## Debugging slowness, SLOWLOG first

Because everything is single-threaded, one slow command blocks every other client, not just the one that issued it. That makes the debugging order different from a normal database:

1. **`SLOWLOG GET`** first, always. It shows exactly which commands crossed the slow threshold, with microsecond timing.
2. Look for `KEYS`, `FLUSHALL` on a big keyspace, or a single `HGETALL` on a huge hash, the usual offenders.
3. Check for a hot key concentrating traffic on one Redis thread's worth of work regardless of how many clients are connected.
4. Check `INFO commandstats` for which command type dominates total time.
5. Check `CLIENT LIST` for a connection count spike, which points at a connection leak rather than a slow command.
6. Check memory usage and eviction stats, since an eviction storm produces latency that looks like slowness but is actually memory pressure.
7. Check replication, if any reads are served from replicas.
8. Only after all of that, look at network and infra metrics.

The numbers for steps 5 to 7 all come out of `INFO`:

| Command | Field to read |
| --- | --- |
| `INFO memory` | used memory against max memory, plus the fragmentation ratio |
| `INFO stats` | `evicted_keys`, a rising count means the cache is thrashing |
| `INFO clients` | `connected_clients` and `blocked_clients`, a climb means a leak |
| `INFO replication` | how far behind each replica is |

> [!tip] Why SLOWLOG comes before infra metrics
> A single blocking command explains 100 percent of a latency spike on a single-threaded system. Checking CPU or network first, before ruling out one bad command, is checking the less likely cause first.

---

## Two production traps

> [!warning] Connection exhaustion
> Each client connection costs Redis a file descriptor and a little memory. An application that opens a new connection per request instead of pooling can exhaust Redis's connection limit under load, causing errors that look like Redis is down when it is actually just out of connection slots.

> [!danger] An exposed Redis is a full compromise, not a data leak
> Redis with no `requirepass` and no network restriction, reachable from the public internet, is a common breach vector. Commands like `CONFIG SET dir` plus `SAVE` can write an attacker-controlled file to disk, which has been used to plant SSH keys or web shells. Treat network exposure as seriously as the auth setting itself.

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[redis-use-cases]] | `Databases/redis/` | the ten use cases and the Node cache-aside implementation |
| [[caching-problems]] | `Databases/redis/` | stampede, avalanche, penetration and eviction, a caching-specific failure list |
| [[redis-cluster]] | `Databases/redis/` | hash slots and scaling, a different mechanic from single-instance internals |
