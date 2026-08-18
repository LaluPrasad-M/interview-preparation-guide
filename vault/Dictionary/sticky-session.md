# Sticky Session

> [!tldr]
> The load balancer sends every request from one client back to the same server, instead of spreading requests freely. Also called session affinity.

You need it when the server keeps something in its own memory that the next server would not have: an in process session, an open WebSocket, a partially uploaded file. The load balancer pins the client with a cookie or by hashing its IP address.

It works, and it fights everything you want from horizontal scaling.

| | Sticky | Stateless |
| --- | --- | --- |
| Adding a server | existing clients stay put, so the new one fills up slowly | takes its share of traffic immediately |
| One server dies | every client pinned to it loses its state | requests just go elsewhere, nobody notices |
| Load spread | uneven, one server can be hot while others idle | even |
| Deploys | restarting a pod disconnects its clients | rolling restart is invisible |

The usual fix is to move the state out rather than route around it. Sessions go into Redis, so any server can serve any request, and long lived connections are handled by a dedicated connection layer that keeps shared state elsewhere. Then the load balancer is free again.

> [!tip] Sticky is a symptom, not a strategy
> It is a reasonable stopgap and a poor destination. Every scaling ladder ends with stateless application servers, because they are the only kind you can add, remove and restart without thinking.

**Shows up in:** [[scaling-stages]], [[websockets-and-sse]], [[where-to-look-by-component]].
