# Dictionary Candidates: Backend, Security, Cloud, AI

Terms explained inline while rewriting these four areas, with no existing note or dictionary entry of their own.

| Term | One-sentence meaning | Note |
| --- | --- | --- |
| Base64URL | A URL safe version of Base64 that swaps `+` and `/` for `-` and `_`, so the value can sit in a query string without escaping. | `Backend/api-design/api-design-fundamentals.md` |
| Content Security Policy (CSP) | A response header that tells the browser which sources of scripts and content it may load, so an injected script from anywhere else is refused. | `Security/cross-site-scripting.md` |
| IaaS / CaaS / FaaS | The cloud service ladder: IaaS hands you a raw server, CaaS a place to run containers, FaaS just a function, with less of your own management at each step. | `Cloud/aws/compute/ec2-ecs-lambda.md` |
| Blue-green deployment | Two identical environments where you deploy to the idle one, test it, then flip traffic to it instantly, so rollback is just flipping back. | `Cloud/kubernetes/kubernetes-basics.md` |
| Readiness probe / liveness probe | A liveness probe checks whether the app is still alive and restarts it if not; a readiness probe checks whether it can serve traffic yet and pulls it from the load balancer until it can. | `Cloud/kubernetes/kubernetes-basics.md` |
| Service mesh | A dedicated infrastructure layer, like Istio or Linkerd, that handles service to service traffic (mTLS, routing, observability) without changing application code. | `Cloud/kubernetes/kubernetes-basics.md` |
| GitOps | Using a Git repository as the single source of truth for infrastructure and deployments, with a controller that keeps the live system matching it. | `Cloud/cicd/pipelines.md` |
| Infrastructure as code (IaC) | Managing infrastructure as versioned, repeatable code, like Terraform, instead of manual changes through a console. | `Cloud/cicd/pipelines.md` |
| OIDC | A protocol that lets a workload request a short lived identity token from a trusted issuer at run time, so no long lived credential sits in storage. | `Cloud/cicd/github-actions.md` |
| Context poisoning | When irrelevant material in a model's context window confuses it into a worse answer. | `AI/token-optimization.md` |

Terms not logged because they already have a home: idempotency key, HMAC, timing safe comparison, replay attack (`Security/webhook-signatures.md`); rate limiting, token bucket, sliding window, fixed window, least privilege (`Security/hardening.md`, `Security/authorization.md`); JWT, RBAC (`Security/jwt.md`, `Security/authorization.md`); XSS, stored/reflected/DOM based (`Security/cross-site-scripting.md`); canary release, exponential backoff, CDN (existing `Dictionary/` entries); idempotency, saga, outbox, two phase commit, optimistic/pessimistic locking (`Backend/idempotency.md`, `Backend/api-failure-scenarios/`); HPA, VPA, KEDA, Helm, DaemonSet, StatefulSet (`Cloud/kubernetes/kubernetes-basics.md`, each with its own table row and explanation, not an aside).
