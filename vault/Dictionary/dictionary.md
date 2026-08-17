# Dictionary

> [!tldr]
> One entry per jargon word that does not have a full note of its own. Short definition, then a pointer to where it actually gets used.

---

## A to Z

| Term | Meaning |
| --- | --- |
| [[canary-release]] | ship a new version to a small group of users first, then widen it if nothing breaks |
| [[cdn]] | a cache layer in front of your load balancer, serving copies of your static files from a machine near the user |
| [[exponential-backoff]] | double the wait between retries so you stop hammering a service that is already struggling |

Only three terms are filled in so far. The rest get added as the rewrite surfaces words that need one, not all at once.

---

## Filed elsewhere

A term never gets a dictionary entry if it already has a real note. Three examples worth knowing about, since they are exactly the kind of word someone might expect to find here first.

| Note | Where | Why there |
| --- | --- | --- |
| [[idempotency]] | `Backend/` | it needs more than a one line definition, so it is a note, not an entry |
| [[sharding]] | `Databases/mongodb/` | shard key properties and scatter gather need the full note |
| [[jwt]] | `Security/` | the three parts and the signature maths need the full note |
