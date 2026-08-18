# GitOps

> [!tldr]
> A Git repository holds the desired state of your infrastructure, and a controller running inside the cluster continuously reconciles reality to match it. Nobody deploys by hand.

The important word is reconcile. The controller does not just apply your change once, it keeps comparing the live cluster against the repository forever. Someone editing a deployment by hand gets quietly reverted, because the repository is the truth and the cluster is a copy.

Argo CD and Flux are the two common controllers. Both watch the repository, notice a new commit, and roll the cluster forward to whatever it declares.

| | Push based pipeline | GitOps, pull based |
| --- | --- | --- |
| Who talks to the cluster | your CI runner, holding cluster credentials | a controller already inside the cluster |
| Deploy is | a pipeline job that ran `kubectl apply` | a merged commit |
| Rollback is | rerun an older pipeline and hope | `git revert`, then the controller does the rest |
| Manual change made at 2am | stays until someone notices | reverted automatically, and visible as drift |
| Audit trail | pipeline logs | the commit history, with reviewers attached |

> [!example]- Rolling back a bad release
> The release is a commit that bumped the image tag from `v1.4` to `v1.5`.
> Rolling back is `git revert` on that commit and pushing it. The controller sees the repository now asks for `v1.4` and moves the cluster back.
> Both the break and the fix are in the same history as the code, reviewed the same way.

> [!warning] Secrets do not go in the repository
> The whole model wants everything declared in Git, and plaintext credentials are the one thing that must not be. Sealed Secrets, SOPS or an external secret store cover that gap, and skipping this step is how a private repository becomes a credential leak.

It only works if the state is written down at all, which is what [[infrastructure-as-code]] provides.

**Shows up in:** [[pipelines]], [[designing-the-four-layers]], [[deploy-pipeline]].
