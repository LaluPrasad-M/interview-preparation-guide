# Observability Platform

> [!tldr]
> Metrics and logs are different workloads and need different stores. Alerts are evaluated off the Kafka stream, not by polling the database every second.

---

## The problem

Collect metrics, logs and events from servers, applications, microservices and network devices, then provide dashboards, alerting, search and analytics to customers.

---

## The architecture

```text
Applications / Devices
          |
          v
   Ingestion APIs
          |
          v
        Kafka
          |
 +--------+--------+
 |        |        |
 v        v        v
Metrics  Logs    Events
Worker   Worker  Worker
 |        |        |
 v        v        v
ClickHouse Loki  ClickHouse
          |
          v
       Grafana
          |
          v
   Dashboards
   Alerts
   Analytics
```

---

## The flow

A server sends:

```json
{
  "host": "server-1",
  "cpu": 85,
  "memory": 70,
  "timestamp": 12345
}
```

The metrics API validates the tenant, authentication and schema, then publishes to `metrics-topic`. Kafka stores the event, metric workers consume it and write to ClickHouse, and Grafana queries ClickHouse to update the dashboard.

---

## Why Kafka

Without it:

```text
Client -> Database
```

A storage slowdown means a slow database, then a slow API, then data loss.

With it:

```text
Client -> Kafka -> Database
```

A storage slowdown just means consumer lag. The system survives.

**Topics.** `metrics-topic`, `logs-topic`, `events-topic`.

**Partition key.** `tenantId`, so one customer's data always lands together. That gives ordering, tenant isolation and horizontal scaling.

---

## Why ClickHouse

**The question.** Why not a document store?

**The answer.** Observability workloads are analytical. Typical queries are average CPU over the last 24 hours, P99 latency over 7 days, or the top 10 servers by memory. Those are aggregation heavy, which is exactly what a columnar store is optimised for. See [[clickhouse]].

### The schema

```text
tenant_id
host_id
metric_name
metric_value
timestamp
tags
```

**Partitioning.** Partition by `toDate(timestamp)`, creating a partition per day. Most queries ask for the last 24 hours or the last 7 days, so only recent partitions are scanned.

**Sharding.** Shard by `hash(tenant_id)`, for tenant isolation and horizontal scale.

---

## Downsampling

Do not keep one second metrics for a year.

| Resolution | Retention |
| --- | --- |
| Raw | 7 days |
| 1 minute average | 30 days |
| 5 minute average | 90 days |
| 1 hour average | 1 year |

Storage drops dramatically, and nobody queries second level data from ten months ago.

---

## Why Loki separately for logs

```text
Application -> Log API -> Kafka -> Loki -> Grafana
```

**The question you should expect.** Why not put logs in ClickHouse too?

Metrics are numeric and aggregation heavy, for example `AVG(cpu)`. Logs are text search, for example finding "database timeout". Different workload, different storage.

---

## Alerting

```text
Kafka -> Alert Worker -> Email / Slack / PagerDuty
```

A rule looks like CPU above 90 percent for 5 minutes.

> [!tip] Why not query the database every second
> Polling ClickHouse continuously is expensive and scales with the number of rules times the number of tenants. Evaluating alerts from the Kafka stream costs nothing extra, because the data is already flowing past.

---

## Grafana

This is the visualisation and investigation layer. It queries both ClickHouse and Loki, and shows metrics, logs, dashboards and alerts in one UI.

---

## The questions this design answers

Why Kafka, why ClickHouse, why Loki, why partition by tenant. Being able to answer all four beats bluffing through tracing internals you have not worked with.
