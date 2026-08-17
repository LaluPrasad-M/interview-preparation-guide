# SLI, SLO and SLA

> [!tldr]
> An SLI is the metric you actually measure, an SLO is the internal target for it, and an SLA is the external promise with consequences if you miss it.

A service level indicator might be "p99 latency" or "percentage of successful requests." The objective is the number you aim to hit, say 300ms p99. The agreement is what you tell a customer, usually looser than the objective, so there is margin before a breach costs money or trust.

A circuit breaker dashboard tracking "dependency SLA breach" is watching the SLA layer; the error budget behind it is tracking the SLO.

**Shows up in:** [[scaling-stages]], [[timeouts-and-circuit-breakers]], [[circuit-breaker]].
