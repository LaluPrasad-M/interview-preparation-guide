# Scaling from Zero to Millions of Users

> [!tldr]
> Nine stages from a single server monolith to a fully distributed system. Each stage exists because the previous one broke.

---

## The parts

| Note | Covers |
| --- | --- |
| [[scaling-stages]] | the nine numbered stages from monolith to fully distributed system |
| [[scaling-ladders]] | workload specific scaling strategies and ladders for read, write and mixed systems |

---

## What breaks first in horizontal scaling

Database connections break.

**What breaks.** DB connection limits, slow queries, DB crashes under load.

**Why.** Each new instance opens its own DB connections. One server means 50 connections, which is fine. Twenty servers means 1000 connections, and most databases have hard connection limits.

**How to fix it.** Connection pooling (HikariCP, PgBouncer), lower per instance connection counts, read replicas, caching reads with Redis, moving to async and background processing.

**The interview insight.** The database often becomes the first bottleneck in horizontal scaling.
