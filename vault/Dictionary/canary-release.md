# Canary Release

> [!tldr]
> Send the new version to a small slice of real users first, watch what happens to them, and widen it only if nothing breaks.

The name comes from caged canaries carried into coal mines. The bird reacted to bad air before the miners did, so it was an early warning at small cost. Firefox does the same thing with nightly and beta builds, where a small willing group runs new code long before everyone else.

> [!example]- A typical ramp
>
> ```text
> 5%    for 30 minutes    watch error rate, p99 latency, and the one business metric that matters
> 25%   for an hour       same checks, now with enough traffic for the numbers to mean something
> 100%                    full rollout
> ```
> At any step, a bad number means you route that slice back to the old version and nobody else ever saw it.

> [!tip] The point is blast radius
> A broken release hits 1 percent of users instead of all of them, and you find out from real traffic rather than from your test suite.

> [!warning] It only works if you can see the canary separately
> If the canary's errors are mixed into one aggregate dashboard, a 1 percent slice failing completely barely moves the overall line and you will miss it. Tag metrics by version, then compare canary against baseline side by side.

Compared with [[blue-green-deployment]], a canary is cheaper because you never run two full environments, and safer because real users hit the new code gradually. The trade off is that the rollout takes hours instead of seconds, and both versions run at once, so they have to tolerate each other's data.

**Shows up in:** [[designing-the-four-layers]], [[kubernetes-basics]], [[config-management]], [[zero-downtime-migration]], [[jio-cinema]], [[design]].
