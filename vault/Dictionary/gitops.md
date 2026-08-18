# GitOps

> [!tldr]
> A Git repository is the single source of truth for infrastructure and deployments, and a controller keeps the live system matching it.

Tools like ArgoCD or Flux watch the repository and reconcile the cluster to whatever it declares, rather than someone running `kubectl apply` by hand. A change is a pull request, reviewed like code, and rollback is reverting the commit.

**Shows up in:** [[pipelines]], [[designing-the-four-layers]], [[deploy-pipeline]].
