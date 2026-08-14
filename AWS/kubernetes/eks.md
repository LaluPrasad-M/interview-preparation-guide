# EKS, Elastic Kubernetes Service

> [!tldr]
> EKS is Kubernetes managed by AWS. You still write Kubernetes, and AWS runs the control plane so you do not have to.

---

## What it is

Amazon Elastic Kubernetes Service lets you run, scale and manage Kubernetes applications without handling the control plane yourself. AWS takes care of cluster maintenance, security and updates.

The control plane is the part of Kubernetes that decides what runs where, and running it yourself means keeping several servers healthy, patched and in agreement before you have deployed anything of your own. That is the work EKS removes. See [[kubernetes-basics]] for the pieces it manages.

---

## Why teams use it

| Reason | Detail |
| --- | --- |
| Fully managed control plane | AWS handles provisioning, scaling and security of the cluster itself |
| Integrates with AWS | works with IAM, VPC, ALB, EBS and CloudWatch |
| Highly available and secure | automatic upgrades, multi availability zone support, encryption |
| Auto scaling | works with both Kubernetes autoscalers and AWS Auto Scaling |
| Flexible | run workloads on EC2 instances or on Fargate |

The AWS services it leans on:

| Service | Provides |
| --- | --- |
| Amazon VPC | secure networking |
| AWS IAM | authentication and authorisation |
| Elastic Load Balancer | traffic into the Kubernetes workloads |
| Amazon CloudWatch | logs and performance monitoring |
| AWS Auto Scaling | dynamic resource allocation |

---

## EKS against ECS and Lambda

| | EKS | ECS | Lambda |
| --- | --- | --- | --- |
| **Control plane** | AWS managed | AWS managed | fully serverless |
| **Orchestration** | Kubernetes | AWS ECS | none |
| **Scaling** | pods and nodes | tasks | instant |
| **Best for** | multi cloud, and teams who already know Kubernetes | AWS native container workloads | event driven tasks |

The honest way to choose between EKS and ECS: ECS is simpler and ties you to AWS, while EKS is more work and gives you a skill and a configuration that move to another cloud. If nobody on the team knows Kubernetes and nobody plans to leave AWS, ECS wins. Full comparison including EC2 in [[ec2-ecs-lambda]].

---

## Where it sits in the pipeline

EKS is the last stage in [[deploy-pipeline]]: it pulls the image from ECR and replaces the running pods with it.
