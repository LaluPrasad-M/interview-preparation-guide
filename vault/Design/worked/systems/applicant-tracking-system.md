# Multi Tenant Applicant Tracking System

> [!tldr]
> Strongly relational, so SQL. The interesting parts are optimistic locking on stage transitions, and separating the transactional workload from the search workload.

---

## Functional requirements

A company creates jobs. Candidates apply. Candidates move across stages:

```text
APPLIED -> SCREENING -> INTERVIEW -> OFFER -> HIRED / REJECTED
```

Recruiters filter by stage, experience, skills and location. Resumes are uploaded and parsed. Every stage change is audit logged.

---

## Non functional requirements

10,000 companies as a multi tenant SaaS, 100,000 candidates per company, a high read workload dominated by filtering and search, strong consistency for stage transitions, under 300 ms search latency, and async resume parsing.

---

## The special constraints

Always state these as part of the functional requirements. They are the invariants the schema has to enforce.

Tenant data must be strictly isolated, with no cross company access. Only one canonical application per job per candidate. Valid stage transitions must follow the defined workflow graph. Concurrent updates must not cause lost updates. A rejected candidate cannot reapply within 6 months. A hired candidate cannot reapply for the same job. An active application in a non terminal stage cannot be duplicated.

See [[invariants]] for which of these belong in the database and which belong in the service layer.

---

## Why SQL for the core

**Strong relationships.** Company to recruiter is one to many, company to jobs is one to many, job to candidate is many to many through applications, and application to stage history is one to many. That is strongly relational.

**ACID is required.** Stage transitions must be consistent, duplicate applications must be impossible, and referential integrity matters.

**Multi tenant filtering.** Composite indexes on `(company_id, stage)`, `(company_id, job_id)` and `(company_id, created_at)` give efficient tenant level isolation.

**Where a document store still fits.** Raw resume JSON, AI embeddings and activity logs. The transactional core stays in SQL. See [[sql-vs-mongodb]].

---

## The schema

```text
companies
  id (PK)
  name
  created_at

recruiters
  id (PK)
  company_id (FK)
  email (UNIQUE)
  role

jobs
  id (PK)
  company_id (FK)
  title
  description
  status (OPEN / CLOSED)
  INDEX (company_id, status)

candidates
  id (PK)
  company_id (FK)
  name
  email
  experience_years
  location
  resume_url
  INDEX (company_id, experience_years)
  INDEX (company_id, location)

applications           -- the many to many bridge
  id (PK)
  company_id
  job_id (FK)
  candidate_id (FK)
  stage
  version              -- for optimistic locking
  created_at
  UNIQUE (job_id, candidate_id)

stage_history          -- append only audit log
  id
  application_id
  old_stage
  new_stage
  changed_by
  changed_at
```

`UNIQUE (job_id, candidate_id)` is what prevents duplicate applications, at the database rather than in code.

---

## Stage transitions and concurrency

**The problem.** Two recruiters update the same application simultaneously. Without control, one update is silently lost.

> [!warning] A transaction alone is not enough
> Transactions prevent simultaneous writes. They do not prevent a logical overwrite, where the last write wins and the first recruiter's change vanishes.

**The solution, optimistic locking.**

```sql
UPDATE applications
SET stage = 'INTERVIEW',
    version = version + 1
WHERE id = ?
AND version = 3;
```

If rows affected is 0, there was a conflict.

**Why it works.** Read, validate and write happen in one atomic statement, it detects any concurrent modification, and it requires no blocking.

**The less general alternative** is `WHERE stage = 'SCREENING'`, which only catches a stage specific conflict. A version column catches everything. See [[locking-strategies]].

---

## Search strategy

A recruiter wants Python, plus 5 years, plus Bangalore, plus stage equals interview.

**Postgres only, with JSONB and a GIN index.** Possible: store skills as JSONB and index them. But ranking is weak, fuzzy search is poor, it is CPU heavy on the database, and it is hard to scale.

**The hybrid, recommended.** Postgres is the source of truth, Elasticsearch is a search projection.

```text
Insert candidate in the DB
   -> Index searchable fields in Elastic
   -> Search in Elastic
   -> Fetch details from the DB
```

**Why Elasticsearch.** An inverted index maps every token to a list of documents. BM25 gives relevance scoring, boosting and fuzzy matching. And it is distributed by design, with shards and parallel search.

> [!tip] The key principle
> Separate the transactional workload from the search workload.

See [[typeahead-search]] for the scatter gather mechanics.

---

## Resume upload and parsing

```text
Upload resume -> S3
Insert candidate (status = PARSING)
Insert row in the outbox table
COMMIT
```

The outbox gives atomic database write plus event persistence.

The worker then reads the outbox, pushes to a queue, the parser extracts skills, the database is updated, and Elastic is re indexed.

**Why the outbox.** It prevents both failure modes: a database write succeeding while the message is lost, and a message being sent while the database write fails. See [[distributed-transactions]].

---

## Scaling

The hierarchy, in order: query optimisation, proper indexing, a Redis cache for dashboard counts, read replicas, partitioning by `company_id`, and sharding by `company_id` only if needed.

**Partitioning.** By `company_id`, and by `created_at` for large history, which enables partition pruning.

**Sharding.** The shard key must align with the access pattern. `company_id` is a good key. `candidate_id` is a bad one, if most queries filter by company, because every query becomes a scatter gather.

| Concept | Purpose |
| --- | --- |
| Replication | scale reads |
| Partitioning | manage large tables |
| Sharding | scale storage and writes |

See [[replication-partitioning-sharding]].

---

## Failure handling

| Problem | Solution |
| --- | --- |
| Duplicate application | `UNIQUE(job_id, candidate_id)` |
| Concurrent stage update | optimistic locking |
| Resume parsing crash | queue retry |
| Search index mismatch | a reindex job |
| Multi tenant leakage | always filter by `company_id` |

---

## The concepts this design teaches

A lost update is not the same as a dirty write. A row level lock is not the same as logical concurrency safety. Version based optimistic locking. The shard key must match the access pattern. The scatter gather problem, and the hot shard issue. A separate search engine for ranking. The outbox pattern for async reliability. And the scaling hierarchy: index, cache, replica, partition, shard.
