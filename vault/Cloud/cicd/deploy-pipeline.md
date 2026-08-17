# Deployment Pipeline

> [!tldr]
> How a microservice gets from your laptop to production on AWS: Git, then a CI/CD build into a Docker image, then ECR to store it, then EKS to run it.

---

## The three phases

**Code development.** Write code in a local Git repository, push to GitHub or whatever else you use for version control.

**Build and deployment.** The CI/CD pipeline triggers automatically. It builds the code, creates a Docker image, and pushes that image to Amazon Elastic Container Registry (ECR). Amazon Elastic Kubernetes Service (EKS) then picks up the latest image from ECR and deploys the updated application.

**Maintenance.** EKS keeps the service running and handles three jobs on its own:

| Job | How |
| --- | --- |
| Load balancing | AWS ALB or ELB spreads traffic across the running copies |
| Scaling | based on your configuration, usually the Horizontal Pod Autoscaler (HPA) |
| Self healing | a failing container gets restarted without anyone being paged |

When a new image is pushed to ECR, the running pods get replaced with the new version.

> [!warning] The push alone does not cause that
> Kubernetes does not watch a registry. Something has to update the Deployment: a step in the CI pipeline, a `kubectl rollout restart`, or a [[gitops|GitOps]] controller that notices the change. The original notes describe this as automatic, and the accurate version is in their own list further down, where "auto-replacement on new push" is a **configured deployment policy** rather than default behaviour. It is worth knowing, because "who actually triggers the rollout" is a normal follow-up question.

---

## The same thing in more detail

**Creating Docker images.** The image holds the application code, the runtime, the libraries and every dependency needed to run it. That is what makes it behave the same on your machine and in the cluster.

**Pushing images to ECR.** Tag the image with the repository URL, then push it with the Docker commands in [[ecr-commands]].

**Configuring EKS.** The cluster is configured to pull from ECR, using project templates, Terraform configuration files and Helm charts.

**Deploying applications.** The deployment references the image stored in ECR, and Kubernetes uses it to create and manage the containers.

---

## Replicas and the Service object

In a Kubernetes deployment you specify the number of pods you want, called replicas, and Kubernetes makes sure that many are running.

The Service object then gives you one stable endpoint in front of them and spreads incoming traffic evenly across the pods.

That pairing is what gives you scalability and reliability. The replicas provide the capacity, the Service hides the fact that there is more than one of them, and the client never needs to know which pod answered. More on the pieces in [[kubernetes-basics]].

---

## What else the application touches

**Data storage in S3.** The application stores data in S3 buckets, reached with AWS credentials, meaning IAM roles or access keys, and read or written through the S3 APIs and URLs. See [[s3-basics]].

**ECR image management.** Push and delete operations in ECR are role specific, controlled by IAM policies. Not everyone who can read the registry can delete from it.

**Configuration files.** A Makefile and YAML files hold the parts that change between environments:

- the ECR repository location
- the EKS cluster ID
- the deployment policy, for example rolling updates, or automatic replacement when a new image is pushed
