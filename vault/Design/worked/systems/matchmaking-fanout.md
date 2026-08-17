# Asynchronous Matchmaking and Notification Fan Out

> [!tldr]
> One event becomes 500 individual tasks, deliberately. Passing the array of 500 to one worker means a crash at ID 250 double spams the first 249.

---

## The problem

A user opens a sports app and creates a game: "need 3 intermediate players for 5-a-side football at Turf X at 8 PM".

The system must find users who play football, are intermediate, and live within 10 km, then push alerts to their phones. If we synchronously query the database and loop through hundreds of HTTP calls to a push provider during the API request, the host's app freezes and the connection times out.

**The objective.** Build an asynchronous event driven fan out architecture that returns `202 Accepted` to the host instantly, decouples the heavy geospatial querying, and efficiently dispatches hundreds of push notifications without overwhelming downstream providers.

---

## Functional requirements

**Ingest.** Accept the game creation request instantly.

**Matchmake.** Filter the global user base by sport, skill level and a 10 km geospatial radius.

**Fan out.** Break the matched user list into individual notification tasks.

**Dispatch.** Check user notification preferences, push against email, and send the alerts via external APIs.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | high write to task amplification. One game creation might trigger 500 to 5,000 internal notification tasks |
| Performance | API response to the host under 50 ms, end to end delivery to players' phones under 5 seconds |
| Availability against consistency | availability. Creating the game is mission critical, but a 10 second notification lag is acceptable |
| Concurrency | thousands of games created simultaneously during peak hours |
| Edge cases | failed pushes needing retries, preventing duplicate notifications, and graceful degradation if the push provider is down |

---

## The architecture

```text
============== PHASE 1: INGESTION AND EVENT TRIGGER ======================

      +-------------------------------------------+
      |               HOST USER APP               |
      +---------------------+---------------------+
                            | 1. POST /v1/games (Sync)
                            v
      +-------------------------------------------+  2. Save Game State
      |            GAME API (Node.js)             +--------+
      +---------------------+---------------------+        |
                            | 3. Publish Event             v
                            v                    +--------------------+
           +---------------------------------+   |  MONGODB CLUSTER   |
           | KAFKA TOPIC: 'game.events'      |   | (Source of Truth)  |
           | (Event: Game_Created)           |   +--------------------+
           +------+-------------------+------+
                  |                   |
================= | = PHASE 2: MATCHMAKING AND FAN-OUT ====================
                  |                   |
                  | 4a. Poll          | 4b. Poll (true pub/sub advantage)
                  v                   v
  +------------------------------+  +------------------------------+
  |  MATCHMAKING WORKER GROUP    |  |  SEARCH INDEXING WORKER      |
  | (Node.js background fleet)   |  | (Updates the search index)   |
  +---------------+--------------+  +------------------------------+
                  | 5. Geospatial query (intermediate players < 10km)
                  v
          +----------------+
          | MONGODB (Users)|  <- Returns 500 User IDs
          +-------+--------+
                  | 6. Publish 500 individual tasks
                  v
           +---------------------------------+
           | KAFKA TOPIC: 'notify.dispatch'  |
           +--------------+------------------+
                          | 7. Poll
                          v
======================= PHASE 3: PREFERENCES AND DISPATCH =================

      +-------------------------------------------+  8. Check prefs
      |     NOTIFICATION DISPATCH WORKERS         +--------+
      +---------+-------------------------+-------+        |
                |                         |                v
   9. Send Push |                         |       +--------------------+
   (HTTP Call)  v                         |       |   REDIS CLUSTER    |
  +-------------------+                   |       | (User preferences  |
  |   PUSH PROVIDER   |                   |       |  and deduplication)|
  +-------------------+                   |       +--------------------+
```

---

## The data flow

**1. Ingestion, steps 1 to 3.** The API receives the payload, saves the game document to MongoDB, and publishes `{ "event": "Game_Created", "game_id": "123", "lat": 12.9, "lng": 77.5 }` to `game.events`. It returns `202 Accepted`.

**2. The matchmaking filter, steps 4 to 5.** The matchmaking worker consumes the event and runs a MongoDB `$near` query using a `2dsphere` index to find users where sport is football, level is intermediate, and location is within 10 km.

**3. The fan out, step 6.** MongoDB returns 500 user IDs. The worker splits the array and publishes 500 separate individual messages to `notify.dispatch`: `{ "user_id": "U_001", "game_id": "123" }`.

**4. The dispatch, steps 7 to 9.** The dispatch worker consumes one task, checks Redis to see if that user has push muted, and if not constructs the payload and fires the HTTP request to the push provider.

---

## API design

**POST** `/v1/games`

```json
{
  "sport": "football",
  "skill_level": "intermediate",
  "venue_id": "turf_x_99",
  "coordinates": { "lat": 12.9716, "lng": 77.5946 },
  "start_time": "2026-08-06T20:00:00Z",
  "required_players": 3
}
```

**Response, 202 Accepted.** The 202 signifies the request is valid and accepted for background processing.

```json
{
  "status": "processing",
  "game_id": "game_12345"
}
```

---

## Database design

Why MongoDB instead of PostgreSQL here? Because it has world class natively optimised geospatial indexing with `2dsphere`, which is perfect for location based matching.

```json
{
  "_id": "U_001",
  "name": "John Doe",
  "preferences": {
     "sports": ["football", "tennis"],
     "football_level": "intermediate"
  },
  "location": {
     "type": "Point",
     "coordinates": [77.5946, 12.9716]
  }
}
```

GeoJSON is always longitude then latitude.

```js
db.users.createIndex({ location: "2dsphere" })
```

The matchmaking query:

```js
db.users.find({
  "preferences.sports": "football",
  "preferences.football_level": "intermediate",
  "location": {
    $near: {
      $geometry: { type: "Point", coordinates: [ 77.5946, 12.9716 ] },
      $maxDistance: 10000 // 10 kilometres in metres
    }
  }
})
```

---

## Kafka against SQS, the critical trade off

### The case for Kafka

**True pub/sub.** Kafka is an append only log. When `Game_Created` fires, the matchmaking worker consumes it, but because Kafka retains the message we can attach a search indexing worker and an analytics worker to read the same event simultaneously, without stealing it from each other.

**Replayability.** If we deploy a bug that causes notifications to fail, the events are still in the log for 7 days. We fix the code, rewind the consumer offset, and replay. SQS deletes the message on successful consumption.

### The case against Kafka

**Error handling.** If the push provider is down, a dispatch worker fails. In SQS the message goes back to the queue via visibility timeout, or drops into a native DLQ. Kafka enforces strict partition ordering, so if a worker fails to process a message and pauses, it blocks the entire partition. Building retry logic in Kafka requires complex retry topics.

**Overkill.** If we only need notifications and do not care about analytics or search, standing up a Kafka cluster for a simple background job is massive operational overkill compared to a managed queue.

### The verdict

Given a mature platform that needs search indexing and analytics alongside notifications, Kafka is the correct enterprise choice.

---

## Follow up questions

### Why 500 messages instead of one array

**Q.** Why not pass the array of 500 IDs in a single Kafka message and let the dispatcher loop through them?

**A.** If we pass an array of 500 to one worker and that worker crashes on ID 250, from an OOM error or a provider timeout, the whole message fails. On retry it starts from the beginning and we double spam the first 249 users.

By executing the fan out pattern, breaking the array into 500 atomic Kafka messages, we guarantee independent failure domains. If one user's push fails, only that message is retried. It perfectly isolates failures.

### Protecting Mongo from spatial query spikes

**Q.** If 1,000 games are created at 5 PM on Friday, 1,000 spatial queries might spike the CPU and crash the DB. How do you protect it?

**A.** Shift the spatial logic to an in memory datastore using Redis GEO. When users update their locations, write their coordinates to a Redis geospatial index keyed by sport and level, for example `football:intermediate:locations`. The matchmaking worker runs `GEORADIUS` in Redis, which returns nearby user IDs in microseconds, completely offloading the maths from the primary MongoDB cluster.

### DLQs in Kafka for a permanently invalid device token

**Q.** How do you handle DLQs if a specific push keeps failing because of an invalid device token?

**A.** Since Kafka has no native DLQ, implement the non blocking retry pattern. If the dispatch worker gets a `400 Bad Request` from the provider, it catches the exception, publishes that message to a `notify.dlq` topic, and safely commits the offset on the main topic.

A separate cron monitors the DLQ, parses the invalid tokens, and updates MongoDB to remove those dead tokens from user profiles, keeping the pipeline clean.
