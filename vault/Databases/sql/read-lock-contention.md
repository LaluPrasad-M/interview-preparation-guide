# Read Lock Contention

> [!tldr]
> Reads are not free. They are cheaper than writes, but they still participate in the database's coordination machinery, and that is where things get hard.

---

## The mistake

The biggest mistake engineers make is thinking reads are safe and writes are dangerous. That model works only at small scale.

At production scale, reads can quietly become some of the most dangerous operations in the system, because reads are not just fetching data. They participate in the database's concurrency control machinery, and databases are fundamentally coordination systems.

---

## The library analogy

Imagine a giant library. Old databases worked like this: if somebody is reading a book, nobody can edit it, and if somebody is editing it, nobody can read it.

That is classic lock based concurrency. Readers blocked writers and writers blocked readers, which is huge contention.

### MVCC, the photocopy model

Instead of forcing readers and writers to fight over the same book, the database creates versions. The reader gets an old photocopy while the writer edits a new version, so both work simultaneously.

That is the core idea behind PostgreSQL and InnoDB. It is why people say reads do not block writes.

> [!warning] That statement is incomplete
> Eventually somebody must clean old versions, manage memory, synchronise indexes, coordinate metadata and preserve consistency. That is where contention returns.

---

## The production story worth remembering

An engineer runs a query inside a transaction:

```sql
BEGIN;
SELECT * FROM transactions
WHERE created_at > '2026-01-01';
```

It runs for 30 minutes. Meanwhile millions of updates happen.

The database now cannot delete old row versions, because that old transaction may still need them. So it preserves history until the reader finishes.

That creates [[multi-version-concurrency-control|MVCC]] bloat, storage growth, index bloat, vacuum lag, slower queries and cache inefficiency. One innocent read query slowly poisons the entire system.

**The key insight.** The danger is often not the read itself, it is how long the read keeps the snapshot alive. Long running reads are dangerous, especially analytics queries, reporting jobs, exports and huge scans.

That is why production systems separate [[oltp-and-olap|OLTP]] databases from analytics databases.

---

## The metadata lock story

Production traffic is running normally, with thousands of requests doing `SELECT * FROM users`.

An engineer deploys a migration:

```sql
ALTER TABLE users
ADD COLUMN age INT;
```

The schema change needs exclusive metadata access, but reads are still touching the table, so the migration waits. Then new queries queue behind the migration.

API latency spikes, requests time out, and it becomes an outage. And everyone says "but we were only doing SELECTs". This has caused many real outages, especially in MySQL.

---

## The mental shift

People imagine query, row, response. Internally the database manages snapshots, versions, indexes, page caches, latches, metadata, replication, cleanup workers and transaction visibility.

Reads participate in all of it.

---

## Serialisable isolation, the perfect accountant

At low isolation the database is relaxed. At `SERIALIZABLE` it behaves like a perfect accountant, wanting transactions to appear as if they executed one by one in perfect order.

Now even reads become conflict participants.

Two users book the last seat. Transaction A checks:

```sql
SELECT COUNT(*)
FROM seats
WHERE booked = false;
```

Transaction B books the seat simultaneously. The database detects a logical conflict and possible inconsistency. One transaction may abort. A read query is now part of the contention.

---

## [[gap-lock|Gap locks]], the invisible locks

Sometimes the database locks not only rows but the gaps between them, to prevent phantom reads.

```sql
SELECT *
FROM orders
WHERE amount BETWEEN 100 AND 200
FOR UPDATE;
```

The database may lock the existing rows and the insertion gaps, so inserts start blocking. This surprises people because they locked a range, not specific rows.

---

## Hot index contention

At scale even internal memory structures become bottlenecks. Take one viral product, one trending post or one hot inventory item: millions of users then read the same records.

Database threads then compete for index pages, memory latches and cache synchronisation. This is not a SQL lock exactly, it is engine level contention, and knowing the distinction is the senior signal.

---

## The two types of contention

**Logical transaction contention.** The classic kind: a transaction waits, locks conflict, a write lock blocks a read.

**Internal engine contention.** Database internals fight over memory pages, cache structures, latches and synchronisation primitives. This becomes huge at scale.

---

## Why read replicas exist

Production systems isolate heavy reads, reporting and analytics from the primary, because even safe reads can consume I/O, increase cache churn, delay replication, create MVCC bloat and degrade write performance.

> [!tip] The line to remember
> Never think reads are free. Think reads are cheaper, but still participate in coordination. And coordination is where distributed systems become hard.
