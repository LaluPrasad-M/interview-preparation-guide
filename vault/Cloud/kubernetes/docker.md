# Docker

> [!tldr]
> Docker packages an app with everything it needs, the blueprint and the build, so it behaves the same on your laptop and in production.

---

## What Docker does

Docker is a containerisation platform that packages an application with its dependencies to ensure consistency across environments. It guarantees the same behaviour everywhere, simplifies deployment, and is lightweight compared to traditional virtual machines.

| Term | Meaning |
| --- | --- |
| Image | the read only blueprint, dependencies plus code |
| Container | the running instance of an image |
| Dockerfile | the step by step instructions to build the image |
| Registry | storage for images, for example Docker Hub or ECR |

---

## Container against virtual machine

| Feature | Container | Virtual machine |
| --- | --- | --- |
| Weight | lightweight, shares the host OS | heavy, requires a guest OS |
| Startup time | milliseconds to seconds | minutes |
| Isolation | process level | full OS |

---

## Why Kubernetes on top of Docker

Docker packages the app. It does not run many copies of it across many machines, restart the ones that die, or add more when load rises. That is [[kubernetes-basics|Kubernetes]]' job.

> [!tip] The interview answer
> Docker runs containers. Kubernetes orchestrates them at scale, handling self healing, scaling and rolling updates.
