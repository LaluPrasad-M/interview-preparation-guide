# Designing the Four Layers

> [!tldr]
> Four layers to reason through in a design interview, in the order you would actually design them: what the user touches, what keeps things correct, where the data lives, and the machinery that ships and scales all three.

---

## Client

This is the only part of the system your user actually touches. Everything behind it can be perfect and they will still call the product bad if this part is slow or confusing.

### What a good frontend gives you

| What you get | How |
| --- | --- |
| **Better experience** | Readable fonts, buttons where people expect them, sizes neither tiny nor huge, enough contrast to read in sunlight. |
| **Speed** | Smaller files (minified bundles), load parts only when needed (lazy loading), keep what you fetched (caching), wait for the user to stop typing before searching (debounce), redraw only what changed (React's virtual DOM). |
| **Room to grow** | Small reusable components instead of one giant file, so two people can work without stepping on each other. |
| **Safety** | Block injected scripts ([[cross-site-scripting]]), stop other sites acting as your user (CSRF), tell the browser which scripts it may run (Content Security Policy), check both who the user is and what they may do. |

### What a bad one costs

> [!warning] The two ways it goes wrong
> **It gets slow.** Too much JavaScript, components redrawing when nothing changed, heavy animations, huge unresized images.
>
> **It gets hard to change.** Nothing is reusable, state is scattered everywhere, no agreed style, so every feature takes longer than the last.

### Three decisions worth remembering

**Feature flags.** A switch that turns a feature on or off without shipping new code. Useful for showing a feature to ten percent of users first, and for turning something off at 2am without a deploy.

**State management.** One agreed place to keep data the whole app needs, using Redux, Zustand or React Context. Without it, two parts of the screen disagree about what is true.

**SSR or CSR.**

| Approach | Builds the page | Good for |
| --- | --- | --- |
| **SSR** | on the server | fast first screen, search engines can read it, content-heavy pages |
| **CSR** | in the browser | feels snappy once loaded, app-like interactive screens |

---

## Backend

This is where correctness and cost live. Users forgive a plain screen. They do not forgive lost data or a service that falls over when traffic doubles.

### What a good backend gives you

**It stays up as it grows.** A load balancer spreads requests across servers, and autoscaling adds servers when traffic climbs.

| Direction | Means | Catch |
| --- | --- | --- |
| **Horizontal scaling** | add more machines | usually the safer bet |
| **Vertical scaling** | give one machine more CPU and memory | one bigger machine is still one machine that can die |

**Services talk efficiently.**

| Choice | Reach for it when |
| --- | --- |
| gRPC | two services need low latency chatter |
| Kafka | a service should announce something happened and not care who listens |
| REST | ordinary request and response APIs |
| GraphQL | clients want to pick exactly the fields they need |

**It is hard to abuse.** Rate limiting caps how often one caller can hit you. JWT or OAuth proves who they are. Role based access control decides what they may do. Encryption protects data sitting in the database and data moving over the wire.

### What a bad one costs

> [!warning] Two failure shapes
> **Bottlenecks.** Code that stops and waits instead of moving on (blocking I/O), queries scanning more rows than they need, long jobs run inline while the caller waits.
>
> **It cannot grow.** One database instance for everything, services too tangled to deploy separately, no caching so the same expensive answer is computed again and again.

### Three decisions worth remembering

**Caching.** Redis for values you look up constantly. A [[cdn]] for images, video and static files. Query level caching for repeated reads, which is what DataLoader does in GraphQL by batching lookups that happen in one request.

**Observability.** You cannot fix what you cannot see. Datadog, Sentry and SumoLogic collect logs, errors and traces so you can follow one request across several services.

**Rate limiting and circuit breakers.** Two different jobs.

| Guard | Protects you from |
| --- | --- |
| **Rate limiting** | too many requests arriving |
| **Circuit breaker** | a dependency that has already failed. After enough failures it stops calling that service for a while, so one sick service does not drag the rest down |

> [!tip] Pair it with [[exponential-backoff]]
> Retries without backoff turn a brief failure into an outage you caused.

---

## Data

This is the part you cannot easily undo. Code ships again tomorrow. A bad schema follows you for years, and lost data never comes back.

### What a good design gives you

| What you get | How |
| --- | --- |
| **Fast queries** | Indexes so lookups do not read the whole table, and a schema shaped like the questions you actually ask. |
| **Survives failure** | Replication keeps copies on other machines. One leader takes writes, followers copy it, and a follower is promoted if the leader dies. |
| **Trustworthy data** | ACID transactions mean a group of changes all happen or none do, so money never leaves one account without arriving in the other. Event sourcing keeps the list of changes, not just the final state, which gives you an audit trail. |

> [!warning] The N plus one trap
> You fetch a list of one hundred rows, then run one hundred more queries to fill in their details. It looks fine on your laptop with three rows and falls over in production.

### What a bad one costs

**Slow queries.** Full table scans, missing indexes, joins written without thinking about which side is large.

**A ceiling on growth.** One node holding everything, and no plan for splitting the data when it no longer fits.

**Real data loss.** No backups, or backups nobody has ever tried to restore.

### Three decisions worth remembering

**SQL or NoSQL.**

| Store | Choose it when |
| --- | --- |
| **SQL** | the data has a clear shape, relationships matter, you want joins and transactions |
| **NoSQL** | the shape varies, or throughput matters more than strict structure |

**Sharding or replication.** People often confuse the two, so they are worth separating.

| Technique | What it does | Fixes |
| --- | --- | --- |
| **Sharding** | splits one dataset across machines, each holding a slice | data too big |
| **Replication** | copies the same data to several machines | reads too many |

**Backup and recovery.** Automated backups, plus point in time recovery so you can rewind to just before someone ran the wrong statement.

> [!tip] The line worth saying out loud
> A backup you have never restored is not a backup. Practise the restore before you need it.

---

## Deployment

This is the machinery under your code: machines, networking, and the pipeline that ships a change. It decides how fast you recover when something breaks, and what you pay while nothing is breaking.

### What a good setup gives you

| What you get | How |
| --- | --- |
| **Sensible cost** | Machines added when demand rises, removed when it falls, and someone actually watching the bill. |
| **Tolerates failure** | Load balancers so no single machine is critical, and deployments in more than one region so one datacentre problem is not your problem. |
| **Safe releases** | Automated tests before shipping, plus blue green deploys and [[canary-release]]. |

**Blue green deployment.** The new version goes onto a second identical environment, traffic switches over once it looks healthy, and rollback is just switching back.

### What a bad one costs

> [!warning] Three familiar smells
> **Downtime.** No failover plan, and one component whose death takes everything with it.
>
> **Wasted money.** Machines sized for the busiest hour of the year, running all year.
>
> **Scary deploys.** Manual steps, no rollback, a release everyone dreads.

### Three decisions worth remembering

**Containers and orchestration.**

| Tool | Does |
| --- | --- |
| **Docker** | packages an app with everything it needs, so it runs the same on your laptop and in production |
| **Kubernetes** | runs many containers across many machines, restarts the ones that die, adds more when load rises |

**Infrastructure as code.** Write the infrastructure down as files instead of clicking through a console. Terraform works across clouds, CloudFormation is AWS only.

> [!example]- The failure it prevents
> A team hand creates EC2 instances, databases and security groups. As deployments multiply, two engineers configure the same security group differently, and access breaks in ways nobody can explain.
>
> Once the setup lives in files, every environment is built the same way, changes are reviewed like code, and you can roll back to a version that worked. Keeping those files in Git is what people mean by GitOps. Replacing servers instead of editing them is immutable infrastructure.

**Load balancing and autoscaling.** Spread traffic, and add capacity before users feel the spike.

> [!warning] Autoscaling is not instant
> New machines take minutes to start. For a spike you can predict, provision ahead of time rather than trusting it to react. See [[jio-cinema]].
