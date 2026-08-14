# Exponential Backoff

> [!tldr]
> Doubling the wait between retries, so you stop hammering a service that is already struggling.

---

## The pattern

| Retry | Waits |
| --- | --- |
| 1st | 1 second after the failure |
| 2nd | 2 seconds after the 1st retry |
| 3rd | 4 seconds after the 2nd retry |
| 4th | 8 seconds after the 3rd retry |

Each wait doubles.

---

## Why doubling

A service usually fails because it is overloaded. Retrying immediately adds load to something already struggling, so the retries become the outage. Backing off gives it room to recover.

> [!warning] Always cap the retries
> Enough clients retrying forever will keep a service down long after the original problem is gone. Three attempts, then give up and surface the failure.
