# Infrastructure as Code (IaC)

> [!tldr]
> Infrastructure is defined in versioned files instead of clicked together in a console, so an environment can be rebuilt identically from the repository.

Terraform works across clouds; CloudFormation is AWS only. Either way, the same file that describes the infrastructure is what gets reviewed, diffed and rolled back, the same way application code is.

This is what makes GitOps possible: a controller can only reconcile a cluster to a declared state if that state is written down somewhere.

**Shows up in:** [[designing-the-four-layers]], [[pipelines]].
