# Out of Memory Kill (OOM Kill)

> [!tldr]
> The kernel terminates a process the instant it exceeds its memory limit. There is no exception to catch, no cleanup, and no graceful shutdown, because the process is not asked, it is killed.

This is the kernel protecting the machine. Something has to give when memory runs out, so it picks a victim and removes it immediately.

In Kubernetes it appears as a pod status of `OOMKilled` with exit code 137, visible from `kubectl describe pod`. It means the container tried to allocate more than its resource limit allowed. Repeated kills show up as a restart count climbing while the logs end mid sentence with nothing that looks like an error, which is the giveaway: a process that crashed would have said something.

| Looks like | Actually is |
| --- | --- |
| the app crashed with no stack trace | the kernel killed it, so it never got to log |
| a mystery restart loop | the limit is below what a normal request needs |
| a slow leak, fine for hours then gone | memory grew past the limit and hit the wall |

> [!warning] No `try/catch` will ever help here
> There is no error thrown into your code to catch, so the fix is upstream: find what holds memory it should release, stop buffering whole files or whole result sets in memory, or raise the limit if the workload honestly needs more. Streaming a response instead of building it in memory removes a surprising share of these.

**Shows up in:** [[kubernetes-basics]], [[memory-and-queue-collapse]], [[where-to-look-by-component]], [[campaign-messaging-engine]], [[matchmaking-fanout]], [[feature-flags]], [[ai-tool-idempotency]].
