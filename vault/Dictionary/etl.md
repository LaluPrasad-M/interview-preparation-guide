# Extract, Transform, Load (ETL)

> [!tldr]
> Pull data out of the system that produced it, reshape it, and load it into a system built for a different job, which is almost always analytics.

The three words are the three steps, in order. Extract reads from the source, usually the production database or a Kafka stream fed by Change Data Capture (CDC). Transform reshapes rows into the target schema, joining, cleaning and aggregating along the way. Load writes the result into the destination, usually a columnar warehouse such as ClickHouse or BigQuery.

> [!example]- Yesterday's orders becoming a revenue dashboard
> ```text
> extract     read yesterday's rows from orders, order_items, users
> transform   join them, convert currency, drop test accounts, roll up per city per hour
> load        insert into a wide analytics table in ClickHouse
> ```
> The dashboard then scans that one table. It never touches the production database, so a slow analyst query cannot slow down checkout.

The order is not fixed, and the variant has its own name.

| | ETL | ELT |
| --- | --- | --- |
| Where the reshaping happens | in a pipeline, before loading | inside the warehouse, after loading |
| You load | only the finished shape | the raw data, then transform it in place |
| Suits | expensive storage, fixed reports | cheap warehouse storage, changing questions |
| Downside | a new question means rerunning the pipeline | you store a lot of raw data you may never query |

This is the machinery that keeps a transactional system and an analytical system apart. See [[oltp-and-olap]] for why keeping them apart matters in the first place.

**Shows up in:** [[nfr-decision-table]], [[clickhouse]], [[internals]].
