# Service Level Indicator, Objective and Agreement (SLI, SLO and SLA)

> [!tldr]
> Three layers of the same number. The indicator is what you measure, the objective is the internal target you hold yourself to, and the agreement is the looser promise you give a customer with money attached if you miss it.

| Term | What it is | Example |
| --- | --- | --- |
| SLI | the metric, measured from real traffic | p99 latency, or the percentage of requests that succeed |
| SLO | your internal target for that metric | p99 under 300 ms, 99.9 percent success, measured monthly |
| SLA | the contractual promise, plus consequences | 99.5 percent uptime, or the customer gets service credits |

The gap between the objective and the agreement is deliberate. You aim at 99.9 and promise 99.5, so there is room to have a bad afternoon, notice it, and fix it before anything is owed to anyone. An SLO equal to the SLA means every miss is immediately a contractual problem.

The objective is also what makes an error budget possible. A 99.9 percent target over 30 days allows about 43 minutes of failure, and that budget is a number teams can spend: plenty left means ship the risky change, budget nearly gone means stop shipping and fix reliability instead.

> [!tip] Only promise what you measure per user
> An SLI averaged across the fleet can look healthy while one region is failing completely. Measuring the thing a user actually experiences, per request, is what keeps the other two layers honest.

A circuit breaker dashboard tracking a dependency's SLA breach is watching the contractual layer; the error budget behind it is tracking the objective.

**Shows up in:** [[scaling-stages]], [[timeouts-and-circuit-breakers]], [[circuit-breaker]].
