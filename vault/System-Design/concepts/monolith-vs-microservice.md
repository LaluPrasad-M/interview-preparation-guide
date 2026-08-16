# Monolith, Microservice, Nanoservice

> [!tldr]
> Nanoservices are usually an anti pattern. Too many edges means more operational overhead than value.

---

## Side by side

| Feature | Monolith | Microservice | Nanoservice |
| --- | --- | --- | --- |
| Size | one big unit | small bounded services | extremely tiny functions |
| Deployment | one deploy | many deploys | hundreds of deploys |
| Scaling | the whole app | per service | overkill |
| Database | shared | independent | independent |
| Fault isolation | poor | good | poor, too many edges fail |
| Complexity | low | medium | very high |
| Team suitability | small team | mid to large teams | not recommended |
| Best for | MVP, early stage | enterprise scale | serverless only workloads |

---

## The interview answer

"A monolith bundles all logic into a single deployable unit. It is simple but does not scale well from a deployment and team structure perspective.

Microservices split the system into independently deployable components, each owning a specific domain. They scale well and offer fault isolation, but add distributed system complexity.

Nanoservices are overly granular microservices, typically a single function or endpoint per service. They often create more operational overhead than value, and are generally considered an anti pattern unless used in serverless event driven systems."

---

## Related

The failure modes that come with splitting things up are in [[fault-tolerance]] and [[service-layer]].
