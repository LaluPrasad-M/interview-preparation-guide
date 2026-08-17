# High Volume Analytics and Observability Ingestion

> [!tldr]
> Pure throughput plus analytical querying. Batch and compress on the way in, decouple through Kafka, and pre aggregate with materialized views on the way out.

---

## API design: batching and compression

When an AI agent is running it might emit dozens of telemetry events per second: latency metrics, speech to text accuracy, token usage. You cannot open a new HTTP connection per event without crushing your servers.

**Batching.** The orchestration layer buffers events locally, collecting them for 5 seconds or until 500 events are gathered, then sends them as an array in a single POST.

**Compression.** To minimise network bandwidth, a major cloud cost, require the payload to be compressed with `gzip` or `brotli`. The API gateway should accept the `Content-Encoding: gzip` header.

**Endpoint.** `POST /v1/telemetry/batch`

```json
{
  "tenant_id": "org_123xyz",
  "events": [
    { "type": "call_dropped", "latency_ms": 120, "timestamp": "..." },
    { "type": "token_usage", "count": 450, "timestamp": "..." }
  ]
}
```

---

## Database modelling: time series and ClickHouse

PostgreSQL and MongoDB will choke if you constantly insert thousands of records per second while simultaneously running massive aggregations such as average latency over 30 days. You need an OLAP database.

ClickHouse is the right tool here. It is column oriented and built precisely for this use case.

```sql
CREATE TABLE telemetry_events (
    tenant_id String,
    timestamp DateTime,
    event_type String,
    latency_ms Int32,
    token_count Int32
) ENGINE = MergeTree()
ORDER BY (tenant_id, timestamp)
```

**Why this works.** The `ORDER BY (tenant_id, timestamp)` sorts the data on disk. When a client dashboard queries metrics for its specific `tenant_id` over a time range, ClickHouse reads only the exact blocks needed rather than scanning the whole table.

---

## The key interview question

**Q.** How do you model the schema to allow fast reads for the UI dashboard while constantly writing thousands of events per second?

**A.** You decouple the writes from the reads.

**1. The ingestion path.** The Node.js API receives the batched events and immediately dumps them into a Kafka topic, for example `telemetry-events`. It does not write to the database directly. This keeps the API response time fast even under heavy load.

**2. The ClickHouse consumer.** ClickHouse has native Kafka engine integration. It pulls data directly from the topic and writes to disk in large efficient batches via the MergeTree engine.

**3. Read optimisation with materialized views.** Instead of calculating average latency from raw data on every dashboard load, create a materialized view in ClickHouse. As data streams in from Kafka, the view pre aggregates it in the background, rolling data into 1 minute or 1 hour buckets.

When the API queries dashboard data, it queries the aggregated view, not the raw events.

> [!tip] Why this beats querying raw events
> The materialized view turns a query that scans millions of rows into one that scans a few dozen, which is what gives enterprise clients sub second dashboard responses.
