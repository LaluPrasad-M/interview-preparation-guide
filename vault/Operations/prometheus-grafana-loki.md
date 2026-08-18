# Prometheus, Grafana and Loki

> [!tldr]
> Prometheus pulls metrics, Grafana only draws them, Loki carries logs. Mixing up who does what is the most common misconception people repeat in interviews.

---

## The pull model

> [!warning] Grafana does not scrape anything
> Grafana is a dashboard, nothing more. It queries whatever data source you point it at. Prometheus is the one that scrapes.

```text
Prometheus  --- pulls metrics from --->  /metrics endpoint on each service
Grafana     --- queries --->  Prometheus  --- draws the dashboard
```

Prometheus polls each service's `/metrics` HTTP endpoint on an interval, rather than services pushing metrics to it. That pull model means a service just has to expose a text endpoint, and Prometheus decides when to collect, which keeps the collector in control of load instead of every service independently deciding how often to push.

Two more reasons, and the second is the good interview answer:

- Prometheus discovers targets itself, so a new pod is scraped without anyone configuring where to send metrics.
- A failed scrape is itself a signal. With pushing, a silent service and a healthy service that had nothing to say look identical.

---

## Where logs go

Logs are a different workload from metrics, higher volume, unstructured text, not a small set of numbers on a timer. That is why Loki exists as a separate system rather than Prometheus growing a logs feature.

```text
Service writes logs to stdout
   -> Promtail (or another agent) tails the log files
   -> ships them to Loki
   -> Grafana queries Loki the same way it queries Prometheus
```

Grafana is the single pane of glass over both, but the two backends are unrelated systems underneath.

---

## Correlating a spike

A P99 latency spike shows up in Prometheus as a metric. The next question is always "what happened at that timestamp", which Prometheus alone cannot answer, since it never stored the request details.

Jump to Loki, filtered to the same time window and the same service, and read the actual log lines for that minute. This is the practical reason the two systems exist side by side. Metrics tell you something is wrong and roughly when. Logs tell you what specifically happened.

See [[observability-platform]] for the worked design version of metrics and logs as genuinely separate workloads.

---

## How the metrics get onto that endpoint

Nothing appears at `/metrics` by itself. The service records it, usually with `prom-client`:

```js
const client = require('prom-client');

const histogram = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Request latency',
  buckets: [50, 100, 200, 500, 1000],
});

app.use((req, res) => {
  const end = histogram.startTimer();
  res.on('finish', end);
});
```

A histogram counts requests into buckets rather than storing each request, which is what lets Prometheus work out P50, P95 and P99 later without keeping a row per request.
Your buckets decide what you can ask afterwards: if the widest bucket is 1000 ms, everything slower than that lands in one pile and P99 gets vague.

---

## Traces, the third pillar

Metrics and logs still leave one question open. A request touched five services, so which one spent the time?

A trace records one request as a set of timed spans, one per hop, so you read the answer straight off it:

```text
API              10 ms
Auth service     15 ms
Payment service  8000 ms
  DB acquire wait  7500 ms
```

The slow part is not the payment service's own code, it is waiting for a database connection, which no single metric would have told you.

OpenTelemetry is the standard way to produce traces, and Jaeger, Zipkin or a paid APM stores and displays them.

| Pillar | Answers | Tool here |
| --- | --- | --- |
| Metrics | what is wrong, and when it started | Prometheus |
| Traces | where the time went | OpenTelemetry, into Jaeger or Zipkin |
| Logs | why it happened | Loki |

> [!tip] What ties the three together
> One id per request, put on every log line and every span, see [[async-local-storage]]. Without it you have three systems that each know something and no way to line them up.
