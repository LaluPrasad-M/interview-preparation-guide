# Online Transaction Processing and Online Analytical Processing (OLTP and OLAP)

> [!tldr]
> OLTP is the database your application talks to, handling many tiny reads and writes. OLAP is the database your dashboards talk to, scanning enormous amounts of history to produce a few numbers. They pull in opposite directions, so at scale they become separate systems.

| | OLTP | OLAP |
| --- | --- | --- |
| Typical query | fetch or update one order | revenue per city per hour, last 2 years |
| Rows touched | a handful | millions |
| Columns touched | most of the row | 3 out of 60 |
| Stored as | rows together, so one record is one read | columns together, so one column is one read |
| Optimised for | latency per operation and correctness | throughput per scan |
| Example | Postgres, MySQL, MongoDB | ClickHouse, BigQuery, Redshift |
| Concurrency | thousands of small transactions | a few heavy queries |

The layout difference explains everything else. A row store keeps the whole record in one place, which is perfect for `WHERE id = 42` and wasteful when you want one column from ten million rows, because you read the other 59 columns to get it. A column store keeps each column together, so scanning one column reads only that column, and similar values sitting next to each other compress well.

Running the dashboard query against the transactional database is the mistake this distinction exists to prevent. One analyst asking for two years of revenue can saturate the disk and add latency to every checkout at the same time.

> [!tip] The standard shape is both, kept apart
> OLTP stays the source of truth, and changes flow into the analytical store through [[etl]] or change data capture. Analysts get their scans, production keeps its latency, and neither one is tuned against its own grain.

**Shows up in:** [[clickhouse]], [[nfr-decision-table]], [[choosing-a-datastore]].
