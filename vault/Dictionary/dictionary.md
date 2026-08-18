# Dictionary

> [!tldr]
> One entry per jargon word that does not have a full note of its own. Short definition, then a pointer to where it actually gets used.

---

## A to Z

| Term | Meaning |
| --- | --- |
| [[amortised-analysis]] | averaging the cost of an expensive operation across many cheap ones |
| [[backpressure]] | a slow consumer tells a fast producer to hold off instead of drowning in queued work |
| [[base64url]] | a URL safe Base64 variant that swaps `+` and `/` for `-` and `_` |
| [[bloom-filter]] | a probabilistic filter that says definitely not present or maybe present, never a false negative |
| [[blue-green-deployment]] | two identical environments, deploy to the idle one and flip traffic to it instantly |
| [[canary-release]] | ship a new version to a small group of users first, then widen it if nothing breaks |
| [[cardinality]] | how many distinct values a column or key can take |
| [[cdn]] | a cache layer in front of your load balancer, serving copies of your static files from a machine near the user |
| [[cold-start]] | the first request after a restart or expiry hits a system with no warm state to draw on |
| [[content-security-policy]] | a header telling the browser which sources of scripts it may run |
| [[context-poisoning]] | irrelevant material in a model's context window confuses it into a worse answer |
| [[covering-index]] | an index containing every column a query needs, so no second trip to the heap |
| [[cqrs]] | the write model and the read model are kept separate and synced asynchronously |
| [[debouncing-and-throttling]] | debouncing waits for activity to stop, throttling caps execution to once per interval |
| [[etl]] | pull data from a source, reshape it, and load it into a destination built for analytics |
| [[exponential-backoff]] | double the wait between retries so you stop hammering a service that is already struggling |
| [[fsync]] | the system call that forces buffered writes to durable storage |
| [[gap-lock]] | a lock on the empty space between index rows, not on a row itself |
| [[gitops]] | a Git repository is the source of truth, and a controller reconciles the live system to match it |
| [[hot-key]] | one key or partition gets so much traffic the node holding it saturates |
| [[iaas-caas-faas]] | the cloud service ladder from raw server, to containers, to just a function |
| [[immediately-invoked-function-expression]] | a function defined and run in the same statement, so nothing leaks into the surrounding scope |
| [[in-sync-replicas]] | the replicas caught up with the leader right now, eligible for promotion |
| [[infrastructure-as-code]] | infrastructure defined in versioned files instead of clicked together in a console |
| [[jwks]] | the public endpoint where an identity provider publishes the keys needed to verify its tokens |
| [[last-write-wins]] | the write with the later timestamp silently overwrites the other in a conflict |
| [[leader-election]] | a group of nodes agrees on exactly one of themselves to coordinate |
| [[multi-version-concurrency-control]] | each transaction sees its own snapshot, so readers and writers never block each other |
| [[mutual-tls]] | both sides of a connection present a certificate, proving identity in both directions |
| [[oidc]] | a workload requests a short lived identity token from a trusted issuer at run time |
| [[oltp-and-olap]] | OLTP serves live transactional traffic, OLAP serves large analytical queries |
| [[out-of-memory-kill]] | the kernel kills a process outright when it exceeds its memory limit |
| [[p99-latency]] | the response time only the slowest 1 percent of requests exceed |
| [[poison-message]] | a message that consistently fails processing no matter how many times it is retried |
| [[qps]] | the number of requests a system handles each second |
| [[quorum]] | a write or read counts as successful once enough replicas acknowledge it, not all of them |
| [[readiness-and-liveness-probes]] | liveness restarts a dead app, readiness pulls a not yet ready one out of rotation |
| [[rebalance-storm]] | consumers keep rebalancing back to back instead of settling |
| [[reference-equality]] | React compares whether a value is the same object in memory, not whether it looks the same |
| [[sargable]] | a WHERE clause the database can answer with an index seek |
| [[server-side-rendering]] | the server builds the full HTML page before sending it |
| [[service-mesh]] | a dedicated infrastructure layer that handles service to service traffic without touching application code |
| [[skip-list]] | a linked list with extra layers of shortcuts, giving logarithmic search without tree rebalancing |
| [[sli-slo-and-sla]] | the metric you measure, the internal target for it, and the external promise with consequences |
| [[sticky-session]] | the load balancer routes every request from a client to the same server |
| [[structural-typing]] | TypeScript matches types by shape, not by declared name or ancestry |
| [[thundering-herd]] | a hot cache key expires and every waiting request rebuilds it at the same instant |
| [[tombstone]] | a delete recorded as a marker instead of physically removing the data |
| [[ttl]] | how long data is allowed to stay valid before it expires |
| [[type-erasure]] | TypeScript strips every type completely before emitting plain JavaScript |
| [[write-ahead-log]] | the database writes down what it is about to do before it does it |
| [[write-amplification]] | one logical write turns into many physical writes |

---

## Filed elsewhere

A term never gets a dictionary entry if it already has a real note, or an established redirect to one. These are exactly the kind of words someone might expect to find here first.

| Note | Where | Why there |
| --- | --- | --- |
| [[idempotency]] | `Backend/` | it needs more than a one line definition, so it is a note, not an entry |
| [[sharding]] | `Databases/mongodb/` | shard key properties and scatter gather need the full note |
| [[jwt]] | `Security/` | the three parts and the signature maths need the full note |
| [[indexing]] | `Databases/mongodb/` | the ESR rule is one part of a bigger note on compound index design |
| [[building-blocks]] | `Design/system-design/` | consistent hashing is explained there as part of the distributed cache building block |
| [[typeahead-search]] | `Design/worked/systems/` | the scatter gather query pattern is worked through there against a real fan-out |
| [[var-vs-let]] | `JavaScript/language/` | the temporal dead zone is explained there alongside hoisting, where it belongs |
