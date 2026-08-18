# Service Mesh

> [!tldr]
> An infrastructure layer, usually Istio or Linkerd, that takes over all service to service network traffic. Retries, encryption, routing and metrics move out of your code and into the platform.

The mechanism is a sidecar proxy. Every service instance gets a small proxy container beside it, and all traffic in and out goes through that proxy instead of straight to the network. Your code still calls `http://billing/charge`; the proxy is what actually opens the connection.

| Concern | Without a mesh | With a mesh |
| --- | --- | --- |
| Retries and timeouts | a library in each service, per language | one policy, applied to every call |
| Encryption between services | each team wires up certificates | [[mutual-tls]] issued and rotated automatically |
| Traffic splitting for a canary | application code or load balancer config | a routing rule, no deploy |
| Metrics and traces per call | whatever each team remembered to add | uniform, because the proxy sees every request |
| A polyglot fleet | the same logic rewritten in 4 languages | none of it in any language |

The catch is real cost. Every call now passes through two extra proxies, adding a small amount of latency, and the mesh itself is another distributed system to run, upgrade and debug. When something breaks it is genuinely harder to tell whether the fault is yours or the mesh's.

> [!tip] It pays off at fleet scale, not at three services
> The value is removing duplicated network logic from many services in many languages. With a handful of services, a shared HTTP client library does most of the same job for a fraction of the operational weight.

**Shows up in:** [[kubernetes-basics]], [[enterprise-auth-sso]], [[api-gateway]].
