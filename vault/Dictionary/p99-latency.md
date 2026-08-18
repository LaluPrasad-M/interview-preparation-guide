# P99 Latency (99th Percentile Latency)

> [!tldr]
> The response time that only the slowest 1 percent of requests go past. It tells you what your unluckiest users are living with, which an average cannot.

Read it by counting. Out of 1000 requests, 10 came back slower than the P99 number and 990 came back faster. P95 is the same idea with the slowest 50 of them, and P50 is just the middle request.

> [!example]- Why the average hides the problem
> 100 requests come in. 99 finish in 50 ms and one takes 5 seconds.
>
> | Metric | Value | What it tells you |
> | --- | --- | --- |
> | Average | 99 ms | looks healthy, nothing to investigate |
> | P50 | 50 ms | the typical request is fine |
> | P99 | 5000 ms | one user in a hundred waited 5 seconds |
>
> The average is arithmetically correct and practically useless. It reports a latency that not one single request actually experienced.

The tail matters far more than 1 percent sounds, because one screen is rarely one request. A page that makes 20 calls has roughly a 1 in 5 chance of hitting at least one P99 request, so a bad P99 is felt by around 20 percent of page loads, not 1 percent of users.

> [!tip] Percentiles do not average across services
> You cannot add the P99 of three services to get the P99 of the chain, and you cannot average P99 across ten servers to get a fleet P99. Percentiles have to be computed from the raw distribution, which is why histogram metrics exist.

What to do about a climbing P99 is in [[incident-triage]].

**Shows up in:** [[incident-triage]], [[node-profiling]].
