# Dictionary

> [!tldr]
> One entry per jargon word that does not have a full note of its own. Each entry gives the full form, a plain explanation, a worked example or comparison where that helps, and a pointer to where the term actually gets used.

---

## A to Z

| Term | Meaning |
| --- | --- |
| [[amortised-analysis]] | averaging one expensive step across the many cheap ones around it |
| [[backpressure]] | the slow side of a pipe telling the fast side to hold off, instead of drowning in queued work |
| [[base64url]] | URL safe Base64, swapping `+` and `/` for `-` and `_` so the value survives a link |
| [[bloom-filter]] | a few bits that answer "definitely not there" or "maybe there", so you can skip a lookup |
| [[blue-green-deployment]] | two identical environments, deploy to the idle one and flip all traffic across in one switch |
| [[canary-release]] | send the new version to a small slice of real users first, then widen it if nothing breaks |
| [[cardinality]] | how many different values a column or key actually holds, which decides index and shard key quality |
| [[cdn]] | Content Delivery Network, a cache near the user that serves your static files instead of your origin |
| [[cold-start]] | the first request after a restart, deploy or expiry, landing on a system with nothing warmed up |
| [[content-security-policy]] | Content Security Policy, the header telling the browser which sources of scripts it may run |
| [[context-poisoning]] | irrelevant material in a model's context window dragging the answer down |
| [[covering-index]] | an index holding every column a query needs, so the row itself is never fetched |
| [[cqrs]] | Command Query Responsibility Segregation, a write model and a read model kept separate and synced in the background |
| [[debouncing-and-throttling]] | debounce waits for the activity to stop, throttle caps how often it may run |
| [[etl]] | Extract, Transform, Load, moving data from the system that produced it into one built for analytics |
| [[exponential-backoff]] | doubling the wait between retries, with jitter, so retries stop becoming the outage |
| [[fsync]] | the system call that forces buffered writes onto the disk, where a crash cannot lose them |
| [[gap-lock]] | a lock on the empty space between index rows, stopping new rows appearing inside a range |
| [[gitops]] | a Git repository as the desired state, with a controller continuously reconciling the cluster to it |
| [[hot-key]] | one key or partition taking so much traffic that its single machine saturates |
| [[iaas-caas-faas]] | Infrastructure, Container and Function as a Service, the same compute at three levels of abstraction |
| [[immediately-invoked-function-expression]] | Immediately Invoked Function Expression, defined and run at once so nothing leaks into the outer scope |
| [[in-sync-replicas]] | In-Sync Replicas, the Kafka replicas caught up with the leader right now and eligible to replace it |
| [[infrastructure-as-code]] | Infrastructure as Code, infrastructure written in versioned files instead of clicked together in a console |
| [[jwks]] | JSON Web Key Set, the public endpoint publishing the keys needed to verify an issuer's tokens |
| [[last-write-wins]] | Last Write Wins, the later timestamp silently overwriting the other write in a conflict |
| [[leader-election]] | a group of nodes agreeing that exactly one of them is in charge |
| [[multi-version-concurrency-control]] | Multi-Version Concurrency Control, each transaction reading its own snapshot so readers and writers never block |
| [[mutual-tls]] | Mutual Transport Layer Security, both ends of a connection presenting a certificate |
| [[oidc]] | OpenID Connect, the identity layer on top of OAuth 2.0, for user login and for workload identity |
| [[oltp-and-olap]] | Online Transaction Processing against Online Analytical Processing, live traffic against big scans |
| [[out-of-memory-kill]] | the kernel terminating a process the moment it passes its memory limit, with nothing to catch |
| [[p99-latency]] | the response time only the slowest 1 percent of requests exceed, and why an average hides it |
| [[poison-message]] | a message that fails every time, blocking everything behind it until it is moved aside |
| [[qps]] | Queries Per Second, the unit every capacity estimate is built from |
| [[quorum]] | enough replicas acknowledging rather than all of them, with `R + W > N` as the rule |
| [[readiness-and-liveness-probes]] | liveness restarts a broken container, readiness pulls a not yet ready one out of the load balancer |
| [[rebalance-storm]] | a Kafka consumer group rebalancing back to back instead of processing anything |
| [[reference-equality]] | React comparing whether a value is the same object in memory, not whether it looks the same |
| [[sargable]] | Search ARGument ABLE, a `WHERE` clause the database can answer with an index seek |
| [[server-side-rendering]] | Server-Side Rendering, the server building the full HTML before sending it |
| [[service-mesh]] | sidecar proxies taking over service to service traffic, so retries and encryption leave your code |
| [[skip-list]] | a sorted linked list with layers of shortcuts, giving log time search with no rebalancing |
| [[sli-slo-and-sla]] | Service Level Indicator, Objective and Agreement: the metric, the internal target, the external promise |
| [[sticky-session]] | the load balancer pinning every request from one client to the same server |
| [[structural-typing]] | TypeScript matching types by shape rather than by declared name |
| [[thundering-herd]] | a hot cache key expiring and every waiting request rebuilding it at the same instant |
| [[tombstone]] | a delete recorded as a marker, so the deletion itself can replicate and win against a stale write |
| [[ttl]] | Time To Live, how long data stays valid before it expires by itself |
| [[type-erasure]] | the TypeScript compiler stripping every type before emitting plain JavaScript |
| [[write-ahead-log]] | Write Ahead Log, the database recording what it is about to do before doing it |
| [[write-amplification]] | one logical write turning into many physical writes across indexes, logs and replicas |

---

## Filed elsewhere

A term never gets a dictionary entry if it already has a real note, or an established redirect to one. These are exactly the kind of words someone might expect to find here first.

| Note | Where | Why there |
| --- | --- | --- |
| [[idempotency]] | `Backend/` | it needs more than a one line definition, so it is a note, not an entry |
| [[sharding]] | `Databases/mongodb/` | shard key properties and scatter gather need the full note |
| [[jwt]] | `Security/` | the three parts and the signature maths need the full note |
| [[oauth]] | `Security/` | the grant types and the token exchange need the full note, and [[oidc]] links to it |
| [[indexing]] | `Databases/mongodb/` | the ESR rule is one part of a bigger note on compound index design |
| [[building-blocks]] | `Design/system-design/` | consistent hashing is explained there as part of the distributed cache building block |
| [[typeahead-search]] | `Design/worked/systems/` | the scatter gather query pattern is worked through there against a real fan-out |
| [[var-vs-let]] | `JavaScript/language/` | the temporal dead zone is explained there alongside hoisting, where it belongs |
