# Infrastructure Design

> [!tldr]
> The machinery under your code: machines, networking, and the pipeline that ships a change. It decides how fast you recover when something breaks, and what you pay while nothing is breaking.

---

## What a good setup gives you

| What you get | How |
| --- | --- |
| **Sensible cost** | Machines added when demand rises, removed when it falls, and someone actually watching the bill. |
| **Tolerates failure** | Load balancers so no single machine is critical, and deployments in more than one region so one datacentre problem is not your problem. |
| **Safe releases** | Automated tests before shipping, plus blue green deploys and [[canary-release]]. |

**Blue green deployment.** The new version goes onto a second identical environment, traffic switches over once it looks healthy, and rollback is just switching back.

---

## What a bad one costs

> [!warning] Three familiar smells
> **Downtime.** No failover plan, and one component whose death takes everything with it.
>
> **Wasted money.** Machines sized for the busiest hour of the year, running all year.
>
> **Scary deploys.** Manual steps, no rollback, a release everyone dreads.

---

## Three decisions worth remembering

**Containers and orchestration.**

| Tool | Does |
| --- | --- |
| **Docker** | packages an app with everything it needs, so it runs the same on your laptop and in production |
| **Kubernetes** | runs many containers across many machines, restarts the ones that die, adds more when load rises |

**Infrastructure as code.** Write the infrastructure down as files instead of clicking through a console. Terraform works across clouds, CloudFormation is AWS only.

> [!example]- The failure it prevents
> A team hand creates EC2 instances, databases and security groups. As deployments multiply, two engineers configure the same security group differently, and access breaks in ways nobody can explain.
>
> Once the setup lives in files, every environment is built the same way, changes are reviewed like code, and you can roll back to a version that worked. Keeping those files in Git is what people mean by GitOps. Replacing servers instead of editing them is immutable infrastructure.

**Load balancing and autoscaling.** Spread traffic, and add capacity before users feel the spike.

> [!warning] Autoscaling is not instant
> New machines take minutes to start. For a spike you can predict, provision ahead of time rather than trusting it to react. See [[jio-cinema]].
