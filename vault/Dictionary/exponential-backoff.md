# Exponential Backoff

> [!tldr]
> Double the wait between retries, so you stop hammering a service that is already struggling.

| Retry | Waits |
| --- | --- |
| 1st | 1 second after the failure |
| 2nd | 2 seconds after the 1st retry |
| 3rd | 4 seconds after the 2nd retry |
| 4th | 8 seconds after the 3rd retry |

A service usually fails because it is overloaded. Retrying immediately adds load to something already struggling, so the retries become the outage. Doubling the wait each time gives it room to recover.

The wait is `base * 2^attempt`, with `base` typically 100 ms to 1 second depending on how impatient the caller can afford to be.

> [!example]- Why the plain version still causes a spike
> A database blips and 10,000 clients fail at the same instant.
> All 10,000 wait exactly 1 second, then retry together. Then all wait 2 seconds and retry together again.
> The load is lower than a hot retry loop, but it still arrives as synchronised waves, and each wave can knock the recovering service back down.
>
> Adding jitter fixes it by spreading the retries out:
>
> ```js
> const wait = Math.random() * base * 2 ** attempt;   // full jitter
> ```
>
> Now those 10,000 retries are smeared across the window instead of landing on the same millisecond.

> [!warning] Always cap the retries
> Enough clients retrying forever will keep a service down long after the original problem is gone. Three attempts, then give up and surface the failure.

> [!tip] Only retry what is safe to repeat
> Backoff decides when to retry, not whether you should. A read is always safe; a payment is only safe if the endpoint is idempotent, so see [[idempotency]] before retrying a write.

**Shows up in:** [[designing-the-four-layers]], [[third-party-integrations]], [[fault-tolerance]], [[hardening]], [[jio-cinema]], [[caching-and-errors]], [[notification-delivery]], [[service-layer]].
