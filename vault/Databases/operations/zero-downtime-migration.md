# Zero Downtime Migration

> [!tldr]
> Expand, dual write, backfill, validate, read switch, contract. That six step pattern covers most of what gets asked about migrations.

---

## Ask first

Before discussing any migration: what data is moving, does it already exist, can it be derived, or is it completely new?

Adding a `phone` field that never existed needs no backfill. If the data exists elsewhere, it does.

---

## The pattern

```text
Expand
  |
Dual Write
  |
Backfill
  |
Validate
  |
Read Switch
  |
Contract
```

**Expand.** Add the new schema, for example `ADD COLUMN phone` or a nullable field in a document.

**Dual write.** Write to the old and new schema simultaneously.

**Backfill.** Move historical data. It must be batch based, idempotent and retry safe.

**Validate.** Check source count against destination count, plus checksums or hashes.

**Read switch.** Move traffic gradually, 10 percent, then 50, then 100.

**Contract.** Remove the old column, table or collection.

---

## The scenario table

| Scenario | Wrong approach | Production approach | Keyword |
| --- | --- | --- | --- |
| Add a column, SQL | add `NOT NULL` directly | add nullable, deploy code, backfill, then make `NOT NULL` | expand, backfill, contract |
| Add a field, Mongo | assume the field exists everywhere | make the app tolerate a missing field, backfill gradually | backward compatibility |
| Rename a column | rename directly | add new column, dual write, backfill, switch reads, drop old | dual write migration |
| Change a data type | alter the whole table immediately | create a new field, migrate gradually, switch reads | expand and contract |
| Large table migration | one massive `UPDATE` | batch migration jobs | batch processing |
| Large collection migration | `updateMany()` on everything | background migration workers | incremental migration |
| Delete millions of rows | `DELETE` all at once | delete in chunks | chunked deletion |
| Create an index | create during peak traffic | online or concurrent index creation | online indexing |
| Move to a new database | big bang cutover | dual write plus gradual read migration | blue green data migration |
| SQL sharding | stop the app and move data | dual write, validate, gradual cutover | sharding migration |
| Mongo sharding | enable sharding blindly | choose the shard key first | shard key design |
| Schema redesign | immediate replacement | a read compatibility layer | backward compatibility |
| Partitioning large tables | move all data at once | create partitions, migrate gradually | data partitioning |
| Service migration | direct traffic switch | canary or blue green rollout | progressive rollout |
| Database upgrade | stop the database, upgrade | upgrade a replica, fail over, upgrade the primary | rolling upgrade |

---

## The five backfill strategies

**1. Batch migration.** Move a thousand rows at a time. This is the most common approach.

**2. Lazy migration.** Migrate only when a record is accessed: the user logs in, the old format is converted, the new format is saved. This is common in document stores.

**3. Dual read plus dual write.** Read from the new source first, falling back to the old one, and write to both.

**4. Event driven migration.** An event fires, a consumer updates the new schema. This is useful for huge systems.

**5. Snapshot plus CDC.** Snapshot the existing data, capture ongoing changes, replay them. This is used in massive migrations. See [[change-data-capture]].

---

## Idempotency and progress

Migration jobs must be rerunnable. Never use a bare `INSERT`. Use an upsert, `INSERT ... ON CONFLICT`, or `MERGE`.

Why: the worker crashes after rows 1 and 2 succeed, then row 3 fails. You need to restart safely.

Maintain a `migration_status` table storing `last_processed_id`, status and timestamp, so the job can resume.

---

## Reconciliation

The purpose is verifying correctness: record counts, checksums, hashes and ranges.

If the source has 500 million records and the destination has 499,999,995, find the missing records and repair them.

---

## Large deletions

Never `DELETE FROM table` on a huge dataset. It causes locks, a CPU spike, replication lag and enormous transactions.

Batch it instead, deleting 1000 at a time and repeating.

---

## Archiving

**An archive table.** Move `orders` to `orders_archive`, then delete from the main table.

**An archive database.** Move production data to a separate archive store.

**Object storage or a data lake.** This is very common. Hot data stays in the database, and cold data moves to S3 as CSV, Parquet, Avro or JSON.

**Soft delete.** Add a `deleted_at` column instead of deleting. This gives easy recovery, but the table and its indexes keep growing.

### Recovery

From an archive table, `INSERT INTO main_table SELECT * FROM archive_table`. From object storage, restore the file and run an import job. From a backup, restore the snapshot.

---

## Partitioning instead of deleting

Rather than deleting 100 million rows, use monthly partitions.

```text
orders_2025_01
orders_2025_02
orders_2025_03
```

To archive, detach the partition. To delete, drop the partition. Both are fast, because they are metadata operations rather than row by row work.

---

## Database specific notes

**SQL.** `CREATE INDEX CONCURRENTLY` in Postgres avoids blocking writes. Read replicas scale reads, sharding scales writes.

**Mongo.** Documents can exist in different formats and the application handles both, which is schema evolution. Choose the shard key carefully: bad keys are `timestamp`, `createdAt`, `country` and `status`, good ones are `hashed(userId)`, `hashed(orderId)` or a UUID, because they give even distribution and no hot shards.

---

## The risks

**Dual write failure.** The old database succeeds and the new one fails, leaving inconsistency. Solutions are the outbox pattern, retries, reconciliation and idempotent writes.

**Hot shard.** All traffic hits one shard, which needs a better shard key.

**Replication lag.** The migration overloads the replica, so monitor lag, CPU and memory.

---

## What to monitor during a migration

**Database.** CPU, memory, connections.

**Performance.** P95, P99, latency.

**Reliability.** Errors, timeouts.

**Replication.** Replication lag.

**Migration.** Rows migrated, failed rows, retry count.

**Consistency.** Mismatch count.

---

## The one liner

> [!tip] Say this
> I would first make the schema backward compatible, then use an expand and contract approach. New writes would be dual written. Historical data would be backfilled using idempotent batch jobs with checkpoints and reconciliation. Reads would gradually move to the new schema. After validation I would decommission the old schema. Throughout, I would monitor latency, errors, replication lag, migration progress and consistency metrics.

That single answer covers most migration discussion in an interview.
