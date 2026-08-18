# P99 Latency

> [!tldr]
> The response time that only the slowest 1 percent of requests exceed. It is the number that says what your unluckiest users are living with, which an average cannot tell you.

Read it by counting: out of 1000 requests, 10 came back slower than the P99 number and 990 came back faster. P95 is the same idea with 50 of them.

The tail matters more than 1 percent sounds, because one screen usually makes several calls. A user who loads a page with twenty requests has a good chance of hitting the slow one, so a bad P99 is felt by far more than 1 percent of people. What to do about a climbing P99 is in [[incident-triage]].

**Shows up in:** [[incident-triage]], [[node-profiling]].
