# Readiness Probe and Liveness Probe

> [!tldr]
> Two health checks that mean different things. Liveness asks "is this thing broken", and failing it restarts the container. Readiness asks "can it take traffic right now", and failing it just removes the pod from the load balancer.

Kubernetes calls both on a schedule and reacts differently to each, so pointing them at the same endpoint throws away the distinction.

| | Liveness | Readiness | Startup |
| --- | --- | --- | --- |
| Question | are you alive | can you serve | have you finished booting |
| On failure | container is killed and restarted | pod is pulled out of the service | keeps the other two from running yet |
| Should check | the process is not deadlocked | dependencies are connected, caches are warm | nothing, it just buys slow starts time |
| Right for | a hung event loop | a pod still connecting to the database | a JVM or a large migration on boot |

This pairing is what actually delivers a zero downtime rolling deploy. A new pod starts, fails readiness while it opens its database pool and warms its cache, and receives no traffic during that time. Only when it reports ready does the service send requests to it, and only then does the old pod get taken down.

> [!warning] Never check a dependency in a liveness probe
> If liveness returns unhealthy because the database is down, Kubernetes restarts every pod, repeatedly, while the database is already struggling. Now you have a database outage plus a restart storm, and the restarts hide the original cause. Dependency checks belong in readiness, which removes traffic without killing anything.

**Shows up in:** [[kubernetes-basics]], [[pipelines]].
