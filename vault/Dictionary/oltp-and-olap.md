# OLTP and OLAP

> [!tldr]
> OLTP systems handle many small transactional reads and writes for a live application; OLAP systems run large analytical queries over historical data for reporting.

A row oriented Postgres table is built for OLTP: fetch or update one order fast. A column oriented store like ClickHouse is built for OLAP: scan millions of rows but only a few columns, fast, for a dashboard aggregate.

Systems that need both keep OLTP as the source of truth and stream changes into a separate OLAP store, rather than running analytics against the transactional database.

**Shows up in:** [[clickhouse]], [[nfr-decision-table]], [[choosing-a-datastore]].
