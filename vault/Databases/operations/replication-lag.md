# Read Replication Lag

> [!tldr]
> With asynchronous replicas there is always a delay between a write hitting the primary and appearing on a replica. Four standard ways to manage it, depending on your consistency needs.

---

## 1. Read your own writes, session consistency

This is the most common approach for user facing applications. If a user updates their own profile they immediately see the update, while other users might temporarily see the old version.

**Time based routing.** When a user performs a write, set a timestamp in their session token or cookie. For a short window, for example 2 to 5 seconds which comfortably covers normal lag, route all reads for that user directly to the primary. After the TTL expires, route them back to the replicas.

**Version checking.** The database returns a logical sequence number (LSN) or GTID on a successful write. The client passes this ID on its next read. The load balancer checks whether the replica has caught up to that LSN, and if not, routes the read to the primary.

---

## 2. Eventual consistency, accept the lag

Often the best architectural decision is to do nothing, provided the business requirements allow it.

If a user posts a comment they need to see it immediately, so use read your own writes. But if another user is looking at the total like count on that post, it is perfectly fine for that count to be 2 seconds out of date. You intentionally accept the stale read in exchange for high availability and low latency.

---

## 3. Synchronous replication

Instead of updating the primary and returning success immediately, the primary waits until the data is written to the primary and at least one replica before acknowledging the write.

**The trade off.** This guarantees the replica you read from is not stale, but it severely impacts write performance. Your write latency is now tied to the network latency between primary and replica.

---

## 4. Monotonic reads

This guarantees that once a user has seen a newer version of the data, they never see an older version, even if they hit different replicas lagging at different rates.

When a client reads data it notes the timestamp or version. On the next read the client sends that timestamp to the replica. If the replica's data is older, the replica either blocks until it catches up, or the request is routed to a different replica or the primary that is sufficiently up to date.
