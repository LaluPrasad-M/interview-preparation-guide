# The 48 Hour Sprint List

> [!tldr]
> A finite, fixed list for a short loop. Breadth across DSA patterns, plus the eight designs that cover core backend scalability.

---

## DSA, breadth plus specifics

### Strings and custom parsing

- Longest palindromic substring, LeetCode 5, and palindromic substrings, LeetCode 647
- A custom string parser where `$` means a number, `+` means a letter, and `*` means the next 3 letters are identical. A mental dry run of finite state machine logic
- Minimum window substring, LeetCode 76, the sliding window masterclass

### Arrays and intervals

- Maximum subarray, LeetCode 53, Kadane's algorithm
- Merge intervals, LeetCode 56, sorting plus overlap logic
- Subarray sum equals K, LeetCode 560, prefix sums plus hash maps

### Graph, BFS and reachability

- A reachability problem on a 1D array with spikes, moving `+1`, `-1` or `+m`, which needs BFS with a visited set
- Number of islands, LeetCode 200, standard matrix traversal

### Linked lists and pointers

- Reverse linked list, LeetCode 206
- Reorder list, LeetCode 143, testing finding the middle, reversing the second half, and merging

### Stacks and custom data structures

- Next greater element I, LeetCode 496, monotonic stack
- LRU cache, LeetCode 146, hash map plus doubly linked list

The patterns behind these live in [[sliding-window]], [[prefix-sum]], [[intervals]], [[monotonic-stack]], [[bfs-and-dfs]], [[reverse-a-list]] and [[lru-and-min-stack]].

---

## HLD, eight designs

### Tier 1

**1. A booking system.** High concurrency, optimistic against pessimistic locking, and handling double booking. See [[appointment-scheduler]].

**2. A document search system.** The inverted index, Elasticsearch integration, and syncing massive data sets. See [[typeahead-search]].

**3. A real time event streaming system.** Pub/sub, Kafka partitions, consumer groups, and guaranteeing message ordering. See [[partitioning]] and [[consumer-groups-and-offsets]].

**4. A URL shortener.** Distributed ID generation, Base62 encoding, and rapid read caching. See [[distributed-id-generation]].

### Tier 2

**5. A distributed rate limiter.** Token bucket or sliding window log, tracking limits globally across gateways using Redis.

**6. Distributed cache design and eviction.** Consistent hashing, Redis TTLs, and mitigating hot keys where viral data brings down a single node.

**7. Top K and heavy hitters.** Processing a firehose of intent data in real time without melting server memory, using a count min sketch.

**8. The master scale question.** An end to end answer to "how do you make things scale?", covering stateless servers, read replicas and sharding strategies. See [[zero-to-millions]].

---

## The twenty backend design prompts

Mid level interviews often focus on a specific backend component and its trade offs, rather than a whole product. These are open ended by design, leaving scale numbers and tech choices for you to clarify.

1. **A distributed rate limiter** enforcing per user quotas. How do you track and synchronise counts across servers, and which strategy: fixed window, sliding window, token bucket?
2. **An image upload service** with thumbnails at several sizes. The HTTP API, data models, processing pipeline, and how thumbnail generation stays async and retryable.
3. **A follow feature** in a social network. Schema and indexes for follower and followee, efficient list queries, pagination and caching.
4. **A caching strategy for a product details service.** Write through against write around against write back, and how you invalidate when inventory changes.
5. **A background job queue.** Producer API, queue, workers, failure queues, durability across restarts, retry logic.
6. **A fault tolerant notification system.** Templates, preferences, status, transient provider failure, retries, backoff, dead letter queues. See [[notification-delivery]].
7. **Scaling a user profile service 10x**, from 1,000 to 10,000 requests per second. Replication, sharding, caching, gateway changes.
8. **A metrics aggregation service.** Ingesting from thousands of servers and querying aggregates. Which time series store, and how to handle write volume against range queries. See [[observability-platform]].
9. **An e-commerce shopping cart.** Cart and item modelling, the endpoints, atomic updates under concurrency, inventory consistency.
10. **A data migration pipeline for a live database.** Async strategy, keeping new writes consistent via dual write or CDC, rollback. See [[zero-downtime-migration]].
11. **A circuit breaker for an unreliable external API.** See [[circuit-breaker]].
12. **A centralised logging system.** Collection, a searchable store, high write throughput, efficient reads.
13. **A sharding strategy for a large user database.** Partitioning, request routing, re sharding when one shard becomes hot.
14. **A cache for a real time leaderboard.** Serving reads fast, invalidating on score change, staleness against write amplification. See [[realtime-leaderboard]].
15. **A REST API for listing and filtering content.** Pagination tokens, sort order, filters, URL structure, missing resources and oversized responses. See [[api-design]].
16. **An event booking system.** Venues, events, seats, bookings, and preventing double booking through transactions or locking. See [[appointment-scheduler]].
17. **A high throughput counter service.** Millions of increments per second, using sharded counters, batching or approximations like HyperLogLog.
18. **A money transfer API.** Transactional integrity, locking, rollback on partial failure, race conditions. See [[api-failure-scenarios]].
19. **A full text search service.** Indexing for fast search, reflecting document updates, the indexing, query and ranking components. See [[typeahead-search]].
20. **A feature flag service.** Flag and assignment modelling, low latency lookups, propagating changes. See [[feature-flags]].
