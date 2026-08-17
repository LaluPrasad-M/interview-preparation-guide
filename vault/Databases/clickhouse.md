# ClickHouse

> [!tldr]
> Postgres is optimised for serving the application. ClickHouse is optimised for analysing the application's data. They usually coexist.

---

## What it is

A column oriented OLAP database designed for fast analytical queries on massive datasets.

Where it sits: Postgres is the application database, Mongo the document database, Redis the cache, ClickHouse the analytics database.

Typical uses: logs, metrics, traces, business dashboards, product analytics, data warehousing.

> [!tip] The one line answer
> ClickHouse is a columnar analytical database optimised for OLAP workloads. It achieves high query performance through columnar storage, compression, vectorised execution and distributed processing.

---

## OLTP against OLAP

| OLTP | OLAP |
| --- | --- |
| transaction processing | analytics processing |
| many small queries | fewer large queries |
| insert, update and delete heavy | select heavy |
| banking, orders | reports, dashboards |
| PostgreSQL, MySQL | ClickHouse |

---

## Row store against column store

**Postgres, a row store.** Entire rows are stored together.

```text
1, Rahul, India, Android
2, John, USA, iPhone
```

Good for `SELECT * FROM users WHERE id = 1`.

**ClickHouse, a column store.** Each column is stored together.

```text
id:      1, 2
name:    Rahul, John
country: India, USA
```

Good for:

```sql
SELECT country, COUNT(*)
FROM users
GROUP BY country;
```

That reads only the `country` column.

> [!tip] The sound bite
> Analytical queries usually need a few columns across billions of rows. Columnar storage minimises disk reads.

---

## The four reasons it is fast

**1. Columnar storage.** Reads only the required columns. Instead of reading 20 columns, it reads 2.

**2. Compression.** Values within a column are similar, so `India, India, India, India` compresses extremely well. That means less disk, less network and less memory.

**3. Vectorised execution.** Instead of processing row by row, it processes batches of around a thousand rows together, which uses the CPU far better.

**4. Parallel processing.** Multiple CPU cores at once.

---

## The common architecture

```text
Application
     |
     v
 PostgreSQL
     |
     | CDC / Kafka / ETL
     v
 ClickHouse
     |
     v
 Dashboards
```

The application writes to Postgres. Analytics queries run against ClickHouse. See [[change-data-capture]] for the link between them.

**Why not query Postgres directly?** Consider `SELECT COUNT(*) FROM logs WHERE timestamp >= now() - 30 days` on 5 billion rows. Postgres struggles. ClickHouse is designed exactly for that.

---

## Ingestion

ClickHouse loves large batch inserts. It dislikes repeated `UPDATE` and `DELETE`.

> [!tip] The sound bite
> ClickHouse is optimised for append heavy workloads rather than frequent row modifications.

---

## Partitioning, sharding, replication

**Partitioning** is usually by time, for example `2025-01`, `2025-02`, `2025-03`. A query for the last 7 days scans only recent partitions, which means less disk scanning and faster queries.

**Sharding** splits data across machines for horizontal scale.

**Replication** keeps copies for high availability and disaster recovery.

---

## What it is good and bad at

**Excellent.** `COUNT(*)`, `SUM(revenue)`, `AVG(latency)`, `GROUP BY country`, `GROUP BY day`, top N users.

**Poor.** Single row updates, deletes, banking systems, order processing, inventory transactions.

### Against PostgreSQL

| Feature | PostgreSQL | ClickHouse |
| --- | --- | --- |
| OLTP | excellent | poor |
| Analytics | good | excellent |
| Updates | excellent | weak |
| Aggregations | moderate | excellent |
| Billions of rows | challenging | designed for it |
| Transactions | strong | limited |
| Logs and metrics | not ideal | excellent |

---

## The frequent questions

**Why is it fast?** Columnar storage, compression, vectorised execution, partition pruning and parallel processing.

**Why is it suitable for observability?** Observability generates huge volumes of append only logs, metrics and traces requiring large aggregations over time windows. That is exactly the workload. See [[observability-platform]].

**Can it replace PostgreSQL?** Usually no. Postgres handles application transactions, ClickHouse handles analytical workloads, and they coexist.

**Why do analytics databases prefer denormalisation?** Analytics prioritises read performance, and denormalisation removes expensive joins.

**What should not use it?** High frequency transactional systems needing frequent updates, deletes, row level locking and strong ACID guarantees.

---

## The 60 second summary

> [!tip] Memorise this
> ClickHouse is a column oriented OLAP database used for analytics, observability and reporting. Unlike PostgreSQL, which stores rows together, it stores columns together, so it reads only the columns it needs. That reduces disk I/O and improves compression. It is optimised for large aggregations such as `COUNT`, `SUM`, `AVG` and `GROUP BY` across billions of rows. It scales through partitioning, sharding and replication, and it shows up for logs, metrics, traces, dashboards and warehouses. It is excellent for append heavy analytical workloads. It is not a good fit for transaction heavy systems with frequent updates and deletes.
