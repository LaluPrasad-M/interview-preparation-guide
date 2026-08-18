# Service Mesh

> [!tldr]
> A dedicated infrastructure layer, like Istio or Linkerd, that handles service to service traffic without the application code knowing it exists.

A sidecar proxy sits next to every service instance and intercepts its network calls, handling mutual TLS, retries, routing and observability in one place instead of every service reimplementing them.

That is what makes zero trust between internal services practical: a gateway can prove its identity to a downstream service via mesh issued mTLS instead of a spoofable header.

**Shows up in:** [[kubernetes-basics]], [[enterprise-auth-sso]], [[api-gateway]].
