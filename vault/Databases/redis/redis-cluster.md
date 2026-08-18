# Redis Cluster and Hash Slots

> [!tldr]
> Redis Cluster does not use classic consistent hashing. It uses 16384 hash slots. That is a common interview trap.

---

## Can cache misses ever be zero?

No. The goal of consistent hashing is not to eliminate cache misses, it is to minimise the number of keys that get remapped.

Four servers each hold 25 percent of the keys. Add a fifth and each should hold 20 percent, which means roughly 20 percent of the key space must move. Those keys are no longer on their original server, so for them the lookup misses, the value is fetched from the database, and the new node is populated.

**From first principles.** A miss happens because the request goes to node E and node E does not have the data yet. The only ways it could have the data are copying it beforehand or loading it lazily on first access.

**Can misses become almost zero?** Yes, with migration or warmup. When adding a node, the old owners transfer their affected keys, so after migration node E already contains its assigned keys. But network cost increases, rebalancing becomes expensive and migration takes time.

So you trade cache misses against data migration cost.

---

## When a node dies

If node C dies, all keys belonging to C are gone. There is no magic, the memory holding those values disappeared. Requests route elsewhere, the data is absent, and you get misses.

Without replication that is 100 percent misses for C's key range.

> [!tip] What consistent hashing actually guarantees
> It guarantees that roughly `1/N` of keys are affected. It does not guarantee zero cache misses.

---

## How Redis Cluster really works

**Step 1.** Redis computes `CRC16(key)`, then `Slot = CRC16(key) % 16384`.

```text
user:1 -> slot 500
user:2 -> slot 12000
user:3 -> slot 9000
```

**Step 2.** Slots are assigned to nodes.

```text
Node A -> slots 0-5000
Node B -> slots 5001-10000
Node C -> slots 10001-16383
```

**The request flow.** A client wants `GET user:1`. Redis calculates slot 500, which belongs to node A, so the request goes to A.

Note what the key is doing here: the key itself is the shard key.
There is nothing separate to configure, and the split is by hash, not by range, so `user_id` 1 to a million do not land together on one node the way they would in a range sharded database.
That is exactly why the load spreads evenly.

---

## Key tags, when related keys must share a node

A command touching two keys only works if both keys live on the same node, which by default they will not.
Wrapping part of the key in braces tells Redis to hash only that part:

```text
user:{123}:profile
user:{123}:orders
```

Both hash on `123`, so both land in the same slot and the same node.
That is what makes a multi key operation, a transaction, or a Lua script over both keys legal at all.

Use it deliberately.
Tagging too much on one value pushes all of that user's data onto one node, which is how you build a [[hot-key|hot key]] by hand.

---

## Adding a node

Redis does not rehash every key. It moves slots.

```text
Node A: 0-5000

becomes

Node A: 0-2500
Node D: 2501-5000
```

Only those slots move. Conceptually similar to consistent hashing in that it moves a small subset rather than the entire dataset.

**The effect on misses.** When slot 3000 moves from A to D, Redis migrates the keys belonging to that slot, so many keys arrive already populated. That dramatically reduces misses during scaling.

---

## Node failure with replicas

Redis typically runs a primary with a replica. If the primary dies, the replica is promoted and the cached data still exists, so instead of 100 percent misses you get close to zero for that slot range.

> [!warning] The real reason Redis survives failures
> It is replication and failover, not consistent hashing itself.

---

## A hot key still breaks a cluster

Hash slots spread keys across nodes, but one specific key, for example a viral post's like counter, still lives on exactly one node no matter how many nodes the cluster has. If that key gets a disproportionate share of the traffic, the node holding its slot saturates while the rest of the cluster sits idle. Adding more nodes does not fix this, since the hot key does not get smaller or move just because more nodes exist to hold it.

The fix is application level, not cluster level: shard the hot key itself into several keys (see the sharded counter approach in [[redis-use-cases]]), or cache its value at a layer in front of Redis entirely.

---

## The interview summary

**Question.** Does consistent hashing eliminate cache misses when nodes change?

**Answer.** No. Consistent hashing only minimises the number of remapped keys. Misses still occur for moved keys unless data is proactively migrated or replicated. In Redis Cluster the system uses hash slots rather than classic consistent hashing, and rebalancing migrates slots along with their keys, which helps reduce misses during scaling.

See [[building-blocks]] for the consistent hashing ring itself.
