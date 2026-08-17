# Readiness Probe and Liveness Probe

> [!tldr]
> A liveness probe checks whether the app is still alive and restarts it if not; a readiness probe checks whether it can serve traffic yet and pulls it out of rotation until it can.

Kubernetes calls both on a schedule. A failed liveness probe means the container is stuck, so it gets killed and replaced. A failed readiness probe just means not yet, so the pod stays running but is removed from the service's load balancer until it passes again.

Pairing readiness probes with rolling updates is what actually delivers zero downtime deploys: a new pod only receives traffic once it reports ready.

**Shows up in:** [[kubernetes-basics]], [[pipelines]].
