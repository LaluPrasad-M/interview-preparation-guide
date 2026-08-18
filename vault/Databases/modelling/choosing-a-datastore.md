# Choosing a Datastore

> [!tldr]
> Architects do not ask "what is Cassandra?". They ask "why Cassandra instead of Postgres?". Organise everything around when a tool becomes right, and what pain you accept in return.

---

## The memory trick

Postgres is truth. Kafka is events. Redis is speed.

Most business systems start with Postgres.

---

## Relational

| Technology | Choose when | Avoid when | Trade off |
| --- | --- | --- | --- |
| PostgreSQL | transactions, joins, consistency, financial systems, ERP, inventory | massive write scale, petabyte scale telemetry | excellent consistency and SQL ecosystem, harder horizontal scaling |
| MySQL | traditional web applications, [[oltp-and-olap|OLTP]] workloads | heavy analytics, complex reporting | simple and battle tested, but fewer advanced analytical features than PostgreSQL |

---

## Document

| Technology | Choose when | Avoid when | Trade off |
| --- | --- | --- | --- |
| MongoDB | flexible schema, evolving products, JSON heavy APIs | heavy joins, strong relational integrity | high developer productivity, weaker consistency and joins than SQL |
| Couchbase | document storage plus cache like access patterns | complex analytics | faster reads, more operational complexity |

Typical systems: user profiles, catalogs, content systems, CMS, metadata storage.

---

## Wide column: Cassandra

| Choose when | Avoid when |
| --- | --- |
| massive writes | complex joins |
| multi region writes | ad hoc querying |
| time series data | frequent schema evolution |
| telemetry | transaction heavy systems |

**The example.** Telemetry at 10 million metrics per second. Postgres struggles at that rate, and Cassandra handles it easily, because Cassandra optimises for write availability rather than relational queries.

**The trade off.** You gain massive write scale. You lose joins, transactions and easy querying.

> [!tip] The sound bite
> Postgres scales reads first. Cassandra scales writes first.

---

## Search: Elasticsearch

| Choose when | Avoid when |
| --- | --- |
| full text search | as a primary database |
| search relevance | strong transactions |
| log search | financial systems |
| observability search | complex relational workloads |

**The example.** Searching a phrase inside 100 million documents.

**The trade off.** You gain search, ranking and fuzzy matching. You lose transactional guarantees.

> [!tip] The sound bite
> Mongo stores documents. Elasticsearch helps find them.

---

## Analytical: ClickHouse

| Choose when | Avoid when |
| --- | --- |
| analytics | high frequency updates |
| dashboards | OLTP |
| aggregations | transaction systems |
| observability | inventory systems |

**The example.** Revenue by region over the last 30 days, or top customers, across 20 billion rows.

**The trade off.** You gain very fast aggregations, columnar storage and compression. You lose transactional semantics.

> [!tip] The sound bite
> Postgres answers "tell me about order 123". ClickHouse answers "tell me about all orders from the last year".

---

## Key value and in memory: Redis

| Choose when | Avoid when |
| --- | --- |
| low latency | as a source of truth |
| cache | long term storage |
| rate limiting | durable storage |
| sessions | complex analytics |

**The trade off.** You gain sub millisecond access. You lose durability and consistency simplicity.

> [!tip] The sound bite
> Redis is a performance optimisation, not a business database.

See [[redis-use-cases]] for the ten use cases, and [[caching-problems]] for the stampede.

---

## Queues and streaming

### RabbitMQ

| Choose when | Avoid when |
| --- | --- |
| task processing | event replay |
| job queues | event sourcing |
| request and response workflows | huge event streams |

Examples: an email queue, PDF generation, background jobs.

**The trade off.** It has excellent routing, but a poor story for event replay.

### Kafka

| Choose when | Avoid when |
| --- | --- |
| event streaming | simple job queues |
| replay requirements | small workloads |
| audit trail | synchronous workflows |
| multiple consumers | as an RPC replacement |

The example: analytics, audit, notifications, billing and fraud detection all consuming the same event.

**The trade off.** You gain replay, scale and fan out. You accept partitions, consumer lag, rebalancing and operational complexity.

> [!tip] The sound bite
> RabbitMQ delivers work. Kafka records history.

See [[kafka-vs-rabbitmq]] for the full comparison.

---

## Object storage: S3

| Choose when | Avoid when |
| --- | --- |
| files | low latency database lookups |
| images | transactions |
| backups | joins |
| data lakes | relational workloads |

**The trade off.** It offers virtually infinite scale, but it is not designed for `SELECT * WHERE ...` queries.

---

## Distributed coordination: ZooKeeper and etcd

| Choose when | Avoid when |
| --- | --- |
| [[leader-election]] | user data |
| cluster coordination | analytics |
| configuration management | high volume writes |

The questions it answers: who is leader, and which node owns which shard.

---

## Time series: Prometheus

| Choose when | Avoid when |
| --- | --- |
| metrics | logs |
| monitoring | full text search |
| infrastructure observability | as a general purpose DB |

Examples: CPU, memory, latency, Kafka lag.

**The trade off.** It is amazing for metrics, but terrible for logs.

---

## The cheat sheet

| If the architect says | You should think |
| --- | --- |
| I need transactions | Postgres |
| I need flexible JSON documents | Mongo |
| I need billions of writes | Cassandra |
| I need search | Elasticsearch |
| I need analytics over billions of rows | ClickHouse |
| I need sub millisecond reads | Redis |
| I need event replay | Kafka |
| I need background jobs | RabbitMQ |
| I need file storage | S3 |

---

## The comparisons architects love

These are the ones with no universally correct answer, only trade offs.

Kafka against RabbitMQ. ClickHouse against Postgres. Redis against read replicas. Mongo against Postgres. Kafka against direct DB writes.
