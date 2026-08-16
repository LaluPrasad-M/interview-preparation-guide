# The Building Blocks

> [!tldr]
> Twelve components that show up across most designs, each with the analogy that makes it stick and the curveball question that follows it.

Split into four blocks so the tables stay readable.

---

## Block 1: core routing and infrastructure

### Distributed cache, consistent hashing

**The analogy.** Arranging library desks in a circle. If one desk breaks, its books slide to the next, instead of reorganising the whole room.

**The mechanics.** Hashes both the server IPs and the data keys onto the same 360 degree ring. Uses virtual nodes, or vnodes, to ensure data is evenly distributed even when hardware sizes differ.

**The trade off.** Cache invalidation is notoriously difficult. If the database updates but the cache does not, users see stale data.

**The curveball.** What happens if our most popular celebrity goes viral and all requests hit just one node, the hot key problem?

### Rate limiter, at the gateway layer

**The analogy.** The club bouncer, keeping abusive traffic from melting your internal servers.

**The mechanics.** Token bucket or leaky bucket, handled in Redis using atomic Lua scripts so a user's request count is checked and incremented in a single thread safe step.

**The trade off.** High availability against accuracy. Syncing user limits globally across 50 gateways adds latency.

**The curveball.** How do you avoid locking out legitimate users who share a public IP, like a university campus?

### ID generator, Snowflake or UUID

**The analogy.** A decentralised deli counter ticketing system that does not rely on a single boss to hand out numbers.

**The mechanics.** Generates a 64 bit integer combining timestamp, datacenter ID, machine ID and sequence number, allowing distributed time sortable generation.

**The trade off.** Heavily dependent on server clocks. NTP drift, clocks going backward, can cause fatal ID collisions.

**The curveball.** How do you pause or recover if a server's clock drifts backward by 2 seconds?

See [[distributed-id-generation]].

---

## Block 2: data storage and partitioning

### Database sharding

**The analogy.** Splitting a giant phonebook into volumes, A to M and N to Z, so more people can look up names simultaneously.

**The mechanics.** Horizontal partitioning, splitting rows across databases by a shard key such as `User_ID % 4`. Requires an application level routing layer to direct queries to the right database.

**The trade off.** Join operations across shards are incredibly slow or impossible, which forces denormalisation.

**The curveball.** If a celebrity user on shard A has millions of followers scattered across all shards, how do you render their timeline quickly?

### Blob storage and CDN

**The analogy.** The database holds the index card. Blob storage is the physical warehouse holding the heavy, unsearchable crate.

**The mechanics.** Files are stored as immutable objects in buckets. A CDN caches them at edge servers globally, slashing latency for distant users.

**The trade off.** Immutability. To change a single pixel in a 5 GB video, you upload a completely new 5 GB file.

**The curveball.** How do you handle a user uploading a 50 GB file over a spotty mobile network without restarting on failure? The answer is multipart upload.

### Search engine

**The analogy.** Looking at the index at the back of a textbook instead of reading every page to find a word.

**The mechanics.** An inverted index maps terms to document IDs, for example `"apple" -> [Doc 1, Doc 4]`. TF-IDF or BM25 algorithms score relevance.

**The trade off.** Blazing fast to read and search, but CPU heavy and slow to update.

**The curveball.** If your inverted index exceeds the memory of a single machine, how do you scatter queries and gather accurate results?

See [[typeahead-search]] for the scatter gather answer.

---

## Block 3: async and concurrency

### Message broker

**The analogy.** A digital post office. Services drop off letters rather than forcing other services to answer the phone immediately.

**The mechanics.** Decouples systems via an append only log. Producers write events, consumers read at their own pace, and consumer groups give parallel processing.

**The trade off.** You lose instant certainty, strict consistency, in favour of eventual consistency and resilience.

**The curveball.** How do you guarantee a message is processed exactly once if the network glitches during transmission?

### Distributed scheduler

**The analogy.** An alarm clock that wakes a fleet of servers, ensuring only one server does the chore.

**The mechanics.** Consensus algorithms such as Paxos or Raft, or distributed locks such as Redis Redlock, ensure multiple workers do not execute the same scheduled task simultaneously.

**The trade off.** High complexity. If a worker grabs a lock and dies before releasing it, the system halts unless TTLs are set.

**The curveball.** If a task takes 10 minutes but the lock TTL is 5 minutes, how do you stop a second worker starting halfway through?

### Ticket concurrency

**The analogy.** Ten thousand people fighting for one concert ticket in the same millisecond.

**The mechanics.** Pessimistic locking locks the row on read, which is safe but blocks others. Optimistic locking uses a version number, and if the version changes before the user hits buy, the transaction fails.

**The trade off.** Pessimistic prevents checkout failures but lets users hoard seats. Optimistic is fast but frustrates users with cart errors.

**The curveball.** How do you gracefully handle 9,999 failed checkout attempts without crashing your frontend or database?

See [[appointment-scheduler]].

---

## Block 4: domain specific, real time and analytics

### Proximity service, spatial indexing

**The analogy.** Drawing a chessboard over a city map so you only search for drivers in your square, not the whole world.

**The mechanics.** Geohashing, quadtrees or S2 Geometry map 2D coordinates into 1D strings. Adjacent areas share similar string prefixes, making lookups extremely fast.

**The trade off.** Write heavy. Moving objects constantly update coordinates, requiring continuous re indexing.

**The curveball.** How do you optimise writes so 10,000 drivers broadcasting GPS every 3 seconds does not melt your primary database?

See [[proximity-discovery]].

### Heavy hitters and top K

**The analogy.** Guessing the top 10 trends without tallying all 500 million posts.

**The mechanics.** Probabilistic data structures: Count-Min Sketch for frequencies, HyperLogLog for unique counts, combined with stream processors such as Flink.

**The trade off.** Trades 100 percent precision for fixed memory. You get a 99 percent accurate answer using mere megabytes of RAM.

**The curveball.** How do you implement a sliding window so a hashtag that trended yesterday naturally falls off today?

### Real time push

**The analogy.** Leaving a phone call connected permanently so you can talk instantly, instead of hanging up and redialling every 5 seconds, which is polling.

**The mechanics.** WebSockets provide full duplex bidirectional TCP connections. Server sent events provide one way server to client streaming over standard HTTP.

**The trade off.** Stateful connections. A server can only hold a finite number of open TCP connections before maxing out.

> [!warning] The 65k number is often quoted wrong
> Roughly 65,000 is the ephemeral port limit for **outbound** connections to a single destination IP and port. A listening server accepting **inbound** connections is bounded by file descriptors and memory, not by that number, which is why a tuned box can hold a million WebSockets. See the WhatsApp sizing in [[capacity-estimation]].

**The curveball.** If a user switches from Wi-Fi to cellular their IP changes and the connection drops. How does the chat app recover without losing messages?

See [[websockets-and-sse]].
