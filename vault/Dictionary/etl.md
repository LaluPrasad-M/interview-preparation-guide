# ETL (Extract, Transform, Load)

> [!tldr]
> Pull data out of a source system, reshape it, and load it into a destination built for a different purpose, usually analytics.

The classic path is the operational database (or a Kafka stream fed by CDC) as the extract source, some reshaping into the target schema, and a columnar warehouse like ClickHouse or BigQuery as the load destination. It is how an OLTP system and an OLAP system stay separate without analytics queries ever touching production.

**Shows up in:** [[nfr-decision-table]], [[clickhouse]], [[internals]].
