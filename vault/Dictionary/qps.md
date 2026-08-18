# Queries Per Second (QPS)

> [!tldr]
> How many requests a system handles each second. It is the unit every capacity estimate starts from, which is why an interviewer asks for it before anything else.

You will also see requests per second (RPS) and transactions per second (TPS). Same measurement, different habits by team.

> [!example]- Turning users into a number you can design against
> 10 million daily active users, and an average user makes 20 requests a day.
>
> ```text
> 10,000,000 x 20        = 200,000,000 requests per day
> 200,000,000 / 86,400   = about 2,300 QPS average
> 2,300 x 3              = about 7,000 QPS at peak
> ```
>
> That last step is the one people skip. Traffic is not spread evenly across 24 hours, it clusters in a few busy hours, so peak runs somewhere around 2 to 10 times the average depending on the product. You provision for the peak, because that is the number that decides whether the system stays up.

Once you have peak QPS, everything else follows from it: how many application servers, how many database connections, whether a cache is optional or mandatory, how much bandwidth. Getting the QPS wrong makes every number after it wrong too.

> [!tip] Say the assumption out loud
> Nobody is checking your arithmetic against reality, they are checking whether you know what you assumed. "20 requests per user per day, peak at 3 times average" is a defensible design; a QPS number with no stated assumptions is not.

**Shows up in:** [[capacity-estimation]], [[appointment-scheduler]], [[geospatial-discovery]], [[api-gateway]], [[circuit-breaker]], [[realtime-leaderboard]], [[multi-region-cart]], [[webhook-ingestion]].
