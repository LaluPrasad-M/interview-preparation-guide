# EC2 vs ECS vs Lambda

> [!tldr]
> Three ways to run code on AWS, at three levels of abstraction. EC2 gives you a machine, ECS gives you a place to run containers, Lambda gives you somewhere to put a function.

---

## EC2, Elastic Compute Cloud

Think of EC2 as a virtual computer in the cloud.

- You manage the operating system, install the software, and deploy your app.
- You can use autoscaling, but you still handle patching, scaling rules and instance failures.
- Good for long running applications, or when you need full control of the environment.

**Analogy:** renting a physical office. Full control, and you furnish and maintain it yourself.

---

## ECS, Elastic Container Service

A container management service that runs Docker containers.

- Runs either on EC2, where you manage the instances, or on Fargate, where AWS manages them for you.
- Handles deployment and scaling of containers, though you still define the scaling policies.
- Good for microservices, where you want flexibility without managing whole servers.

**Analogy:** a shared workspace with desks. The desks (containers) get assigned as needed, and you look after your space rather than the building.

---

## Lambda, serverless

Event driven and fully serverless. A function execution service.

- No servers, VMs or containers to manage. Write the function, upload it.
- Scales instantly with demand, with no autoscaling rules to write.
- Billed per execution time, so you pay only while it runs.
- Suits short lived work: handling an API request, a database update, processing a file, cron style tasks.
- The limit that decides most designs: **15 minutes maximum per invocation.**

**Analogy:** a vending machine. No office to rent, no desk to book. Press the button, get what you need, and it shuts off immediately.

---

## Choosing

| Feature | EC2 | ECS | Lambda |
| --- | --- | --- | --- |
| **Do you manage servers?** | yes | less, and none with Fargate | no |
| **Scalability** | autoscaling, but slower | container scaling | instant |
| **Billing** | for running instances | for running containers | per function execution |
| **Best for** | full control, long running apps | microservices and containers | short, event driven tasks |

The short version: **EC2** when you need full control of the server, **ECS** when you are working with containers, **Lambda** when you want event driven execution with nothing to manage.

---

## The classification behind it

The same three services, named by how much they hand back to you.

| Model | Service | You handle |
| --- | --- | --- |
| Infrastructure as a Service (IaaS) | EC2 | everything: OS, networking, scaling |
| Container as a Service (CaaS) | ECS, and [[eks]] | the containers, while AWS handles some of the infrastructure |
| Function as a Service (FaaS) | Lambda | only the code |

All three are AWS compute services. The difference is purely the level of abstraction, which is a cleaner way to answer "what is the difference" than listing features.

See also [[why-ec2-is-more-work]] for the question that follows from this, and [[eks]] for the Kubernetes option.
