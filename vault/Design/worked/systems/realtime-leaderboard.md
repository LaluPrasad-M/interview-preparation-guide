# High Scale Real Time Leaderboard

> [!tldr]
> A Redis sorted set is a hash table plus a skip list. That combination gives constant time score lookup and logarithmic time ranking across 50 million players.

---

## The problem

A global ranking system for a massive multiplayer game with 50 million active players. Every time a player gets a kill, their score increases.

With a standard SQL database, `SELECT * FROM players ORDER BY score DESC LIMIT 100` makes the database sort 50 million rows on the fly. At 100,000 requests per second the CPU melts in seconds.

And players do not just want the top 100. They want their own exact global rank, "you are number 4,231,899 out of 50 million". Calculating an exact absolute rank in SQL requires scanning millions of rows.

**The objective.** Build a real time in memory ranking engine handling 50,000 score updates per second and 500,000 reads per second, returning mathematically exact global ranks in under 10 milliseconds.

---

## Functional requirements

**Update.** Increment a user's score in real time.

**Top N.** Fetch the global top 100 instantly.

**Absolute rank.** Fetch a specific user's exact global rank and score.

**Relative rank.** Fetch the 5 players immediately above and below a user.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | 50 million daily active users, extremely read heavy, 50k write QPS against 500k read QPS |
| Performance | P99 read latency under 10 ms, P99 write latency under 20 ms |
| Availability against consistency | availability and partition tolerance for reads, keeping the game running, but eventual durability so scores survive a crash |
| Concurrency | safe atomic increments. Two kills in the same millisecond must both count |
| Edge cases | the tie breaker problem, and restoring 50 million scores to RAM after a total cluster crash |

---

## The architecture

```text
======================= PHASE 1: THE READ/WRITE API BOUNDARY ==========================

      +-------------------------------------------+
      |         CLIENT APP (Game Console)         |
      +---------------------+---------------------+
                            | 1. Sync HTTPS / WebSockets
                            | POST /v1/scores OR GET /v1/leaderboard
                            v
      +-------------------------------------------+
      |             API GATEWAY                   |
      |    (Rate limiting, JWT session auth)      |
      +---------------------+---------------------+
                            | 2. gRPC
                            v
      +-------------------------------------------+
      |     LEADERBOARD SERVICE (Node.js/Go)      |
      |   (Stateless, horizontally scaled pods)   |
      +------+------------------------------+-----+
             |                              |
===========  |  PHASE 2: REAL-TIME ENGINE   |  ========================================
             |                              |
             | 3. Writes (ZINCRBY)          | 4. Reads (ZREVRANGE / ZREVRANK)
             v                              v
  +--------------------------------------------------------------+
  |                        REDIS CLUSTER                         |
  |                (Source of truth for real time)               |
  +----------------------+----------------------+----------------+
  |    REDIS MASTER      |    REDIS REPLICA 1   | REDIS REPLICA 2|
  |  (Handles writes)    |    (Handles reads)   | (Handles reads)|
  +----------+-----------+----------------------+----------------+
             |
===========  |  PHASE 3: DURABILITY AND ASYNC PERSISTENCE ============================
             |
             | 5. Async CDC / write-behind buffer
             v
  +-------------------------------------------+
  |         APACHE KAFKA (Event Bus)          |
  |     Topic: leaderboard.score.updates      |
  +------------------+------------------------+
                     | 6. Poll (batches of 5000)
                     v
  +-------------------------------------------+
  |      PERSISTENCE WORKER (Micro-batch)     |
  |  (Aggregates updates to protect the DB)   |
  +------------------+------------------------+
                     | 7. Bulk SQL UPSERT (every 5 seconds)
                     v
  +-------------------------------------------+
  |     POSTGRESQL / CASSANDRA CLUSTER        |
  |  (Cold storage, disaster recovery,        |
  |   historical analytics)                   |
  +-------------------------------------------+
```

---

## The write path

**1. The kill.** A player scores 50 points and the game server sends `POST /v1/scores { "user_id": "u123", "points": 50 }`.

**2. Atomic in memory update.** The service executes `ZINCRBY global_leaderboard 50 u123` directly against the Redis master.

> [!tip] Why this is magic
> Redis handles this entirely in RAM, and because Redis is strictly single threaded, `ZINCRBY` is mathematically atomic. If 5 concurrent requests try to add 50 points, Redis queues them in its event loop and executes them sequentially. This gives zero race conditions, under 1 ms.

**3. Write behind persistence.** Redis is RAM based, so if the master crashes before replicating the score is lost. To guarantee durability without slowing the game, the service also drops a tiny event into Kafka: `{ "u123": +50 }`.

**4. Micro batching to disk.** The persistence worker consumes Kafka but does not update Postgres instantly. It holds scores in memory, aggregating for 5 seconds. If `u123` scores 10 times in 5 seconds, the worker combines it into a single `+500` update and executes one bulk SQL upsert. That shields Postgres from the 50k write QPS.

---

## The read path

**1. The request.** The user clicks the leaderboard tab.

**2. Read replica routing.** The service routes to a Redis read replica, not the master, keeping the master's CPU free for writes.

**3. Top 100.** `ZREVRANGE global_leaderboard 0 99 WITHSCORES`. Redis traverses its internal skip list and returns the top 100 in roughly 1 ms.

**4. Absolute rank.** `ZREVRANK global_leaderboard u123` returns their exact integer index in logarithmic time.

**5. Relative rank.** The service takes the rank index, subtracts and adds 5, and executes `ZREVRANGE global_leaderboard 4499995 4500005`.

---

## API design

### Increment score

**POST** `/v1/leaderboards/global/scores`

**Headers.** `Idempotency-Key: kill_event_9988`, preventing double counting on network retries.

**Payload.** `{ "user_id": "usr_777", "points_to_add": 150 }`

**Response, 200 OK.** `{ "new_total_score": 1450 }`

We return the new score but not the new rank, because rank calculations are heavier and should not be attached to every bullet fired in a game.

### Get top N and user rank

**GET** `/v1/leaderboards/global?limit=100&include_user=usr_777`

```json
{
  "metadata": { "last_updated": "2026-08-06T10:00:00Z", "total_players": 50000000 },
  "top_players": [
    { "rank": 1, "user_id": "usr_101", "score": 99500 },
    { "rank": 2, "user_id": "usr_202", "score": 98200 }
  ],
  "current_user": {
    "rank": 4500000,
    "score": 1450,
    "relative_neighbors": [
       { "rank": 4499999, "user_id": "usr_abc", "score": 1452 },
       { "rank": 4500001, "user_id": "usr_xyz", "score": 1449 }
    ]
  }
}
```

---

## The data structure, the secret sauce

If you just say "I will use Redis", you fail a senior interview. You must explain how Redis achieves this.

A Redis sorted set is two data structures operating simultaneously.

**A hash table.** Maps `user_id` to score, making finding a user's score a constant time operation.

**A skip list.** This is a multi layered linked list keeping scores perfectly sorted at all times.

> [!question] Why not a B-tree?
> B-trees require heavy rebalancing during inserts, which locks memory. A skip list uses probabilistic balancing, effectively coin flips, to maintain sorting. That makes inserting or updating a score a fast logarithmic operation even with 50 million elements.

**The persistent structure.** PostgreSQL is only used if Redis explodes and we need to rebuild RAM state.

**Table `player_scores`.** `user_id` VARCHAR primary key, `total_score` BIGINT, `updated_at` timestamp. We do not even need an index on `total_score`, because Postgres is purely cold storage, not for querying the leaderboard.

---

## Global sorted set against sharded

**The trap.** "I will put all 50 million users in one Redis sorted set."

**The reality.** A sorted set with 50 million users consumes roughly 5 to 8 GB of RAM, which fits on a single modern server. But a single Redis core processes only about 100,000 commands per second. If the game scales to 200,000 QPS, that single CPU core bottlenecks and crashes.

**The solution, score based sharding.** Split the leaderboard into tiers by score threshold.

| Node | Scores | Players |
| --- | --- | --- |
| Redis Node A | 0 to 10,000, bronze tier | 40 million |
| Redis Node B | 10,001 to 100,000, silver tier | 9 million |
| Redis Node C | above 100,001, gold tier | 1 million |

By sharding on score we parallelise CPU load. If a user crosses 10,001 points, the service executes a `ZREM` on node A and a `ZADD` on node B.

---

## The tie breaker problem

**The scenario.** 10,000 players all have exactly 5,000 points. Redis natively breaks ties by sorting `user_id` strings alphabetically, which is deeply unfair to a player whose username starts with Z.

**The solution, the timestamp hack.** The gaming industry standard is that whoever reached the score first gets the higher rank. Modify the score before sending it to Redis using fractional maths.

```text
True_Redis_Score = Actual_Score + ( 1 - (Timestamp_ms / 10^13) )
```

If player A gets 5000 points at 10:00, their Redis score becomes `5000.98765`. If player B gets 5000 at 10:01, theirs becomes `5000.98760`. Redis sorts perfectly and player A ranks higher. We strip the decimal when displaying it.

---

## Follow up questions

### The entire Redis cluster goes down

**Q.** How do you restore the leaderboard, and how long does it take?

**A.** If we relied only on Postgres cold storage, loading 50 million rows and executing 50 million `ZADD` commands over TCP would take several minutes to an hour, a massive outage.

For rapid recovery we use Redis RDB snapshots alongside Postgres. Redis periodically dumps its exact RAM state to object storage as a binary `.rdb` file. If the cluster dies we spin up a new one pointed at that file, and Redis loads the binary into RAM in seconds. We then replay the last few minutes of the Kafka `leaderboard.score.updates` topic to catch up any scores between the snapshot and the crash.

### Monthly resets

**Q.** On the 1st of every month everyone's score resets to 0. Deleting 50 million records at midnight would lock up the cluster.

**A.** We never delete data from a live sorted set at midnight. We use time boxed keys. The August leaderboard lives in `leaderboard_2026_08`, and at midnight on 1 September the API servers seamlessly start writing and reading from `leaderboard_2026_09`.

The old August key stays in memory for players viewing historical stats. We set a Redis TTL of 30 days on it, so background threads evict it weeks later without any CPU spike.

### A bot polling the top 100

**Q.** A bot polls the top 100 endpoint 10,000 times a second, consuming read replica CPU. How do you protect Redis?

**A.** The top 100 almost never changes from millisecond to millisecond, so there is no reason to query Redis for every request. Introduce an in memory local cache inside the leaderboard service pods.

The pod queries the Redis top 100 once and stores it in local RAM with a TTL of 1 second. For the next 10,000 requests hitting that pod in that second, it returns the JSON instantly from local memory. That reduces load on Redis from 10,000 QPS to literally 1 QPS per pod.
