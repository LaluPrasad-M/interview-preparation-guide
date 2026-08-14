# Why EC2 is More Work Than ECS

> [!tldr]
> A fair question: EC2 has autoscaling and ECS does not do it by itself, so why is EC2 called the manual option? Because autoscaling only adds machines. Everything you then have to do with those machines is still yours.

---

## EC2 with autoscaling

- EC2 instances are virtual machines.
- Autoscaling means AWS adds or removes instances based on demand.
- But you set up and manage those instances: install dependencies, deploy code, configure networking, handle failures, arrange load balancing.
- Even with autoscaling on, you define the scaling rules, manage instance health checks, and deal with updates yourself.

So autoscaling solves one problem, capacity, and leaves every other problem where it was.

---

## ECS

- ECS is a container orchestration service that runs Docker containers.
- It abstracts away much of the work of managing individual EC2 instances.
- Service management is built in, so a failed container gets restarted for you.
- With Fargate, it autoscales without you managing EC2 instances at all.
- Running ECS on EC2 rather than Fargate means you are back to managing the underlying instances, but deploying and scaling the containers is still easier.

---

## The answer in one line

Autoscaling changes how many servers you have. It does not change the fact that they are your servers to patch, configure and deploy to.

ECS with Fargate removes the servers from your job description. That is the difference, and it is about **what you are responsible for**, not about which service can scale.

Full comparison with Lambda in [[ec2-ecs-lambda]].
