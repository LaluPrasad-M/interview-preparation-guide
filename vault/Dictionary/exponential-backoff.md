# Exponential Backoff

> [!tldr]
> Doubling the wait between retries, so you stop hammering a service that is already struggling.

| Retry | Waits |
| --- | --- |
| 1st | 1 second after the failure |
| 2nd | 2 seconds after the 1st retry |
| 3rd | 4 seconds after the 2nd retry |
| 4th | 8 seconds after the 3rd retry |

A service usually fails because it is overloaded. Retrying immediately adds load to something already struggling, so the retries become the outage. Doubling the wait each time gives it room to recover.

> [!warning] Always cap the retries
> Enough clients retrying forever will keep a service down long after the original problem is gone. Three attempts, then give up and surface the failure.

**Shows up in:** [[designing-the-four-layers]], [[third-party-integrations]], [[fault-tolerance]], [[hardening]], [[jio-cinema]], [[caching-and-errors]], [[notification-delivery]], [[service-layer]].
