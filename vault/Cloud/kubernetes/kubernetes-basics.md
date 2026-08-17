# Kubernetes Basics

> [!tldr]
> Kubernetes runs containers across many machines and keeps them running. This whole job, running containers and keeping them alive, is what people mean by container orchestration. Four words carry the model: container, pod, node, cluster.

---

## The building blocks

Think of a restaurant.

| Piece | Is | In the restaurant |
| --- | --- | --- |
| **Container** | a lightweight box holding your app and everything it needs to run | a mini pizza oven that can go anywhere |
| **Pod** | the smallest thing Kubernetes manages, usually one container, sometimes a few | one pizza plus the plate it is served on |
| **Node** | a server, physical or virtual, that runs your pods | one kitchen |
| **Cluster** | many nodes working together, managed as one | the whole restaurant |

The one people get wrong is that Kubernetes does not schedule containers directly. It schedules **pods**, and a pod happens to contain containers. So the smallest thing you can schedule or scale is a pod. Mentally, a pod is one running instance of your app.

Restarting is the exception worth knowing. When a container inside a pod crashes, the kubelet restarts that container in place, according to the pod's `restartPolicy`, without recreating the pod or moving it to another node.

---

## What Kubernetes actually does

- Deploys your apps, choosing which machines they run on.
- Restarts them if they crash.
- Scales them up or down depending on traffic.
- Notices when something is broken and tries to fix it.
- Exposes your app to users through load balancers.

Its four headline features, in the usual vocabulary:

| Feature | Means |
| --- | --- |
| Automated scaling | adjusts workloads based on demand |
| Load balancing | spreads traffic across containers |
| Self healing | restarts failed containers automatically |
| Service discovery | lets applications find and talk to each other |

Kubernetes is open source and runs on premises, in the cloud, or across both.

---

## The core objects

Beyond the four building blocks, a handful of named objects give you control over how pods run and how traffic reaches them.

**Deployment, the most important.** Manages stateless pods, handling scaling, self healing and rolling updates. Mentally, the manager of pods.

**Service.** Provides a stable endpoint and IP, load balancing traffic across dynamic pod IPs. Mentally, the traffic router.

**Ingress.** Routes external HTTP and HTTPS traffic to services based on rules and URLs.

**StatefulSet.** Like a deployment but for stateful apps such as databases and Kafka, guaranteeing strict ordering and persistent network identities.

**DaemonSet.** Ensures exactly one copy of a pod runs on every node, used for logging agents and monitoring tools.

### Configuration and storage

| Type | Use case |
| --- | --- |
| ConfigMap | non sensitive configuration, env vars and properties |
| Secret | sensitive data, passwords and API keys, as base64 |
| PV / PVC | persistent volume, cluster wide storage, and persistent volume claim, a pod requesting a specific size |

> [!tip] The flow, very important
> A user request hits the ingress, routes to a service, which load balances traffic to pods managed by a deployment.

**Deployment against service, the question that comes up.** The deployment manages the lifecycle of pods, the service abstracts their dynamic IPs to provide a stable network endpoint.

---

## Rolling updates, blue green and canary

The "smooth swap when you update the code" further down has a name: a rolling update.

**Rolling updates, the Kubernetes default.** It replaces old pods with new ones gradually, ensuring zero downtime.

**[[blue-green-deployment|Blue green]].** Two identical environments. Blue is live, you deploy to green, test it, and instantly flip the service router to green. The benefit is instant rollback.

**Canary.** Route a small percentage of traffic, for example 5 percent, to the new version and monitor for errors before rolling out completely. See [[canary-release]].

---

## Self healing and probes

Kubernetes notices when something is broken and recreates the pod to match the desired state. It knows a pod is stuck via probes.

**[[readiness-and-liveness-probes|Liveness probe]].** Is the app dead? If it fails, Kubernetes restarts the container.

**Readiness probe.** Is the app ready to serve traffic? If it fails, Kubernetes removes it from the service load balancer until it recovers, which prevents 502 errors during startup. Pairing readiness probes with rolling updates is what gets you zero downtime deploys.

### Debugging CrashLoopBackOff

1. Check pod status: `kubectl get pods`
2. Check logs, the most important step: `kubectl logs <pod-name>`
3. Describe the pod: `kubectl describe pod <pod-name>`, looking for [[out-of-memory-kill|OOMKilled]], probe failures and events
4. Check resources: are memory limits exceeded?
5. Check service routing: is traffic reaching the pods correctly?

**What happens when a whole node fails, not just a container?** A crashed container is restarted in place by the kubelet, per the restarting exception above. A dead node is different: the kubelet on it stops responding, the master node notices, and reschedules those pods onto healthy nodes.

---

## Scaling strategies

Scaling Kubernetes is not always the answer. Sometimes the bottleneck is the database, cache or network, not enough pods. Identify bottlenecks using metrics and traces before blindly scaling Kubernetes.

| Strategy | Purpose | The one liner |
| --- | --- | --- |
| HPA, horizontal | scales pods up and down | HPA increases replica count based on CPU or memory spikes |
| VPA, vertical | scales resources per pod | VPA allocates more CPU or RAM to a single pod, and may require a restart |
| Cluster autoscaler | scales nodes | HPA scales pods, the cluster autoscaler adds nodes when pods are pending |
| KEDA, event driven | scales on external metrics | KEDA scales based on business events, like Kafka lag or queue depth |

> [!tip] The scaling chain reaction
> Traffic spikes, HPA adds pods, nodes run out of capacity so pods stay pending, the cluster autoscaler provisions new nodes, and KEDA scales consumers based on Kafka lag.

---

## Tooling and observability

**Helm and Kustomize.** Package managers for Kubernetes, letting you template manifests for different environments instead of hardcoding values.

**[[service-mesh|Service mesh]], Istio or Linkerd.** A dedicated infrastructure layer for service to service communication, handling [[mutual-tls|mTLS]], advanced traffic routing and deep observability without changing application code.

**Security contexts.** Defining privilege and access control settings for a pod or container, for example ensuring containers do not run as root.

**Observability, day 2 operations.** Metrics via Prometheus for collection and Grafana for dashboards. Logs via the ELK or EFK stack. Traces via Jaeger or a commercial APM to track a request across microservices.

---

## Interview questions

**What is etcd?** The highly available key value store acting as Kubernetes' brain, storing the entire cluster state.

### Phrases to drop

"To maintain the desired state." "To ensure zero downtime, we use readiness probes alongside rolling updates." "Before blindly scaling Kubernetes, I would verify the bottleneck is not the database connection pool or the network."

---

## The scenario that explains it

You have a web app, and you want:

- three copies running at all times
- one to restart if it crashes
- five copies when traffic spikes
- a smooth swap when you update the code

You describe that end state, and Kubernetes works continuously to make reality match it. That is the whole idea: you declare what should be true, rather than writing the steps to make it true. Every feature above is a consequence of that one design decision.

The AWS managed version is [[eks]].
