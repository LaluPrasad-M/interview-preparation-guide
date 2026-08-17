# CI/CD Pipelines

> [!tldr]
> CI/CD automates the whole flow from a code push to a running pod. A code push triggers a build, the build becomes a Docker image, and Kubernetes rolls that image out.

---

## The one paragraph version

Code push triggers CI, which builds and stores a Docker image. Kubernetes deploys that image as pods using a deployment. A service routes traffic to the pods. Kubernetes handles scaling, rolling updates, and automatic recovery from failures.

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

## The flow, restated

Code is pushed, CI tests and builds, the Docker image is tagged and pushed to a registry, CD pulls the image and updates the Kubernetes deployment.

**CI/CD.** Automating that whole flow.

**[[infrastructure-as-code|Infrastructure as code]].** Managing infrastructure as repeatable code, for example Terraform.

**[[gitops|GitOps]].** Using Git as the single source of truth for declarative infrastructure and applications, for example ArgoCD or Flux.

> [!tip] Phrase worth using
> "Rather than manual intervention, we use infrastructure as code."

---

## A pipeline in practice

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

---

## The real world answer format

"When a developer pushes code, it triggers our CI pipeline, which runs tests, builds a Docker image, and pushes it to our registry. On the deployment side, we use Kubernetes deployments to manage our Node.js pods, ensuring rolling updates for zero downtime. A service acts as our stable load balancer. To handle traffic spikes we rely on HPA to scale pods horizontally, while using [[readiness-and-liveness-probes|readiness and liveness probes]] to ensure traffic only hits healthy instances."
