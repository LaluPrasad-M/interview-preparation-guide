# Tombstone

> [!tldr]
> A delete written down as a marker rather than by removing the data. The deletion becomes a fact that can be replicated, ordered and compared against other writes, instead of an absence that carries no information.

Absence cannot win an argument. If a row is simply gone, a replica that receives a late update for it has no way to know the row was deleted on purpose, so it recreates it. A tombstone gives the deletion a timestamp, so it can beat an older write the same way any other write would.

> [!example]- The deleted item that came back
> Two regions hold the same cart. A user removes an item in Mumbai at 10:00:05, and a queued update to that same item arrives in Frankfurt at 10:00:06.
> With a hard `DELETE`, the row is gone in Mumbai, the update recreates it, and replication spreads the resurrected item everywhere. The item reappears in the cart.
> With a tombstone, the row still exists carrying `deleted: true` at 10:00:05, and [[last-write-wins]] compares timestamps. The 10:00:06 update wins on that field but the item stays deleted, because a tombstone is a value, not a hole.

Kafka log compaction uses the same idea with different wording. Publishing a key with a `null` value is the tombstone, and compaction removes that key and its history once it runs, so a compacted topic can represent "this entity no longer exists" rather than just its latest state.

> [!warning] Tombstones accumulate
> They occupy space and still get scanned until a cleanup process removes them, so a table with heavy deletes can end up slower than one with none. Cassandra's classic failure is a query that reads a million tombstones to return zero rows.

**Shows up in:** [[log-compaction]], [[multi-region-cart]].
