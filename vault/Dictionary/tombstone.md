# Tombstone

> [!tldr]
> A delete recorded as a marker instead of physically removing the data, so the deletion itself can replicate and win against a stale write.

In Kafka log compaction, a null valued record is the tombstone that removes a key once compaction runs. In multi-region replication, a hard `DELETE` can lose a race against a late arriving `UPDATE` for the same row, bringing a deleted item back to life.

A tombstone flag with a timestamp fixes that: last write wins compares timestamps, and the newer tombstone stays deleted.

**Shows up in:** [[log-compaction]], [[multi-region-cart]].
