# Kubernetes, Docker and CI/CD

> [!tldr]
> Docker packages the app, Kubernetes runs and manages it at scale, CI/CD automates the whole flow. The Service is the traffic layer, the Deployment is the management layer.

---

## The one paragraph version

Code push triggers CI, which builds and stores a Docker image. Kubernetes deploys that image as pods using a deployment. A service routes traffic to the pods, and Kubernetes handles scaling, rolling updates, and automatic recovery from failures.

> [!tip] The full spoken version
> When a developer pushes code, it triggers a CI pipeline. The pipeline builds a Docker image by packaging the application with its dependencies, then pushes that image to a container registry.
>
> On the CD side, Kubernetes pulls the latest image from the registry and uses a deployment to run it as pods. The deployment ensures the desired number of pods are always running and handles rolling updates when a new version is deployed.
>
> A service sits in front of these pods to provide a stable endpoint and load balance incoming traffic. Kubernetes also ensures self healing by automatically recreating failed pods.

```text
User -> Service -> Pod -> Container (Node.js app)
            ^
   (load balancing happens here)
```

Service is the traffic layer. Deployment is the management layer.

---

## The core mental model

**Docker.** Packaging the app, the blueprint and build.

**Kubernetes.** Running and managing it at scale, orchestration.

**CI/CD.** Automating the whole flow.

**Infrastructure as code.** Managing infrastructure as repeatable code, for example Terraform.

**GitOps.** Using Git as the single source of truth for declarative infrastructure and applications, for example ArgoCD or Flux.

---

## Docker foundation

Docker is a containerisation platform that packages an application with its dependencies to ensure consistency across environments. It guarantees the same behaviour everywhere, simplifies deployment, and is lightweight compared to traditional VMs.

| Term | Meaning |
| --- | --- |
| Image | the read only blueprint, dependencies plus code |
| Container | the running instance of an image |
| Dockerfile | the step by step instructions to build the image |
| Registry | storage for images, for example Docker Hub or ECR |

### Container against VM

| Feature | Container | Virtual machine |
| --- | --- | --- |
| Weight | lightweight, shares the host OS | heavy, requires a guest OS |
| Startup time | milliseconds to seconds | minutes |
| Isolation | process level | full OS |

---

## Kubernetes core objects

Kubernetes is a container orchestration system managing deployment, scaling and self healing of containerised applications.

**Pod.** The smallest deployable unit, running your container. Mentally, one instance of the app.

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

---

## Advanced deployments and zero downtime

**Rolling updates, the Kubernetes default.** Replaces old pods with new ones gradually, ensuring zero downtime.

**Blue green.** Two identical environments. Blue is live, you deploy to green, test it, and instantly flip the service router to green. The benefit is instant rollback.

**Canary.** Route a small percentage of traffic, for example 5 percent, to the new version and monitor for errors before rolling out completely.

---

## Self healing and probes

When a pod crashes, Kubernetes recreates it automatically to maintain the desired state. It knows a pod is stuck via probes.

**Liveness probe.** Is the app dead? If it fails, Kubernetes restarts the container.

**Readiness probe.** Is the app ready to serve traffic? If it fails, Kubernetes removes it from the service load balancer until it recovers, which prevents 502 errors during startup.

### Debugging CrashLoopBackOff

1. Check pod status: `kubectl get pods`
2. Check logs, the most important step: `kubectl logs <pod-name>`
3. Describe the pod: `kubectl describe pod <pod-name>`, looking for OOMKilled, probe failures and events
4. Check resources: are memory limits exceeded?
5. Check service routing: is traffic reaching the pods correctly?

---

## Scaling strategies

Scaling Kubernetes is not always the answer. Sometimes the bottleneck is the database, cache or network. Identify bottlenecks using metrics and traces first.

| Strategy | Purpose | The one liner |
| --- | --- | --- |
| HPA, horizontal | scales pods up and down | HPA increases replica count based on CPU or memory spikes |
| VPA, vertical | scales resources per pod | VPA allocates more CPU or RAM to a single pod, and may require a restart |
| Cluster autoscaler | scales nodes | HPA scales pods, the cluster autoscaler adds nodes when pods are pending |
| KEDA, event driven | scales on external metrics | KEDA scales based on business events, like Kafka lag or queue depth |

> [!tip] The scaling chain reaction
> Traffic spikes, HPA adds pods, nodes run out of capacity so pods stay pending, the cluster autoscaler provisions new nodes, and KEDA scales consumers based on Kafka lag.

---

## Tooling and ecosystem

**Helm and Kustomize.** Package managers for Kubernetes, letting you template manifests for different environments instead of hardcoding values.

```yaml
pipelines:
  branches:
    master:
      - step:
          name: Build & Test
          script:
            - npm install
            - npm test

      - step:
          name: Build Docker Image
          script:
            - docker build -t my-app .

      - step:
          name: Deploy
          script:
            - docker push ...
            - kubectl apply -f deployment.yaml
```

**Service mesh, Istio or Linkerd.** A dedicated infrastructure layer for service to service communication, handling mTLS, advanced traffic routing and deep observability without changing application code.

**Security contexts.** Defining privilege and access control settings for a pod or container, for example ensuring containers do not run as root.

---

## CI/CD and observability

**The flow.** Code push, CI tests and builds, the Docker image is tagged and pushed to a registry, CD pulls the image and updates the Kubernetes deployment.

**Observability, day 2 operations.** Metrics via Prometheus for collection and Grafana for dashboards. Logs via the ELK or EFK stack. Traces via Jaeger or a commercial APM to track a request across microservices.

---

## Interview questions

**Why Kubernetes if Docker exists?** Docker runs containers, Kubernetes orchestrates them at scale, handling self healing, scaling and rolling updates.

**Deployment against service?** The deployment manages the lifecycle of pods, the service abstracts their dynamic IPs to provide a stable network endpoint.

**What happens when a node fails?** The kubelet stops responding, the master node notices, and it reschedules those pods onto healthy nodes.

**What is etcd?** The highly available key value store acting as Kubernetes' brain, storing the entire cluster state.

### The real world answer format

"When a developer pushes code, it triggers our CI pipeline, which runs tests, builds a Docker image, and pushes it to our registry. On the deployment side, we use Kubernetes deployments to manage our Node.js pods, ensuring rolling updates for zero downtime. A service acts as our stable load balancer. To handle traffic spikes we rely on HPA to scale pods horizontally, while using readiness and liveness probes to ensure traffic only hits healthy instances."

### Phrases to drop

"To maintain the desired state." "Rather than manual intervention, we use infrastructure as code." "To ensure zero downtime, we use readiness probes alongside rolling updates." "Before blindly scaling Kubernetes, I would verify the bottleneck is not the database connection pool or the network."
