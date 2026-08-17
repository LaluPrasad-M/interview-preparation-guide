# Out of Memory Kill (OOM Kill)

> [!tldr]
> The kernel kills a process outright when it exceeds its memory limit, no exception to catch and no graceful shutdown.

In Kubernetes this shows up as a pod status of `OOMKilled`, found with `kubectl describe pod`. It means the container tried to use more memory than its resource limit allowed, and the kernel terminated it instantly rather than letting it degrade.

The fix is never a bigger try/catch. It is finding the leak, lowering per-request memory use, or raising the limit if the workload genuinely needs more.

**Shows up in:** [[kubernetes-basics]].
