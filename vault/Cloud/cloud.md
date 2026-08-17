# AWS

> [!tldr]
> Index for everything under `AWS/`. Compute is choosing where code runs, S3 is storage, Kubernetes is orchestration, and Deployment is how a container gets from a Git push to a running pod.

---

## Compute

| Note | Covers |
| --- | --- |
| [[ec2-ecs-lambda]] | the three services, their analogies, the comparison table, IaaS against CaaS against FaaS |
| [[why-ec2-is-more-work]] | why autoscaling does not make EC2 the easy option |

---

## S3

| Note | Covers |
| --- | --- |
| [[s3-basics]] | objects, buckets, keys, the flat namespace, console and CLI |
| [[storage-classes]] | six classes, and the One Zone-IA exception where cheaper really does risk the data |
| [[s3-security]] | IAM against bucket policies against ACLs, and the four encryption options |
| [[s3-lifecycle]] | the transition and expiration rule, field by field |
| [[s3-events]] | Lambda triggers, and the common use cases |

---

## Kubernetes

| Note | Covers |
| --- | --- |
| [[kubernetes-basics]] | container, pod, node, cluster, and what Kubernetes actually does |
| [[eks]] | Kubernetes managed by AWS, and how it compares with ECS and Lambda |

---

## Deployment

| Note | Covers |
| --- | --- |
| [[deploy-pipeline]] | Git to CI/CD to ECR to EKS, the three phases, replicas and the Service object |
| [[ecr-commands]] | login, batch delete, push, and why the token goes through stdin |

---

## Where to learn more

- [AWS walkthrough covering S3, CloudFront, Lambda and DynamoDB](https://www.youtube.com/watch?v=pK52mfm69i0)
- [Jio Cinema system design talk](https://www.youtube.com/watch?v=36N1Bz7qW0A), also linked from [[design]]
