# Kubernetes Basics

> [!tldr]
> Kubernetes runs containers across many machines and keeps them running. Four words carry the whole model: container, pod, node, cluster.

---

## The building blocks

Think of a restaurant.

| Piece | Is | In the restaurant |
| --- | --- | --- |
| **Container** | a lightweight box holding your app and everything it needs to run | a mini pizza oven that can go anywhere |
| **Pod** | the smallest thing Kubernetes manages, usually one container, sometimes a few | one pizza plus the plate it is served on |
| **Node** | a server, physical or virtual, that runs your pods | one kitchen |
| **Cluster** | many nodes working together, managed as one | the whole restaurant |

The one people get wrong is that Kubernetes does not schedule containers directly. It schedules **pods**, and a pod happens to contain containers. So the smallest thing you can schedule or scale is a pod.

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

## The scenario that explains it

You have a web app, and you want:

- three copies running at all times
- one to restart if it crashes
- five copies when traffic spikes
- a smooth swap when you update the code

You describe that end state, and Kubernetes works continuously to make reality match it. That is the whole idea: you declare what should be true, rather than writing the steps to make it true. Every feature above is a consequence of that one design decision.

The AWS managed version is [[eks]].
