# Sticky Session

> [!tldr]
> The load balancer routes every request from the same client to the same server, instead of spreading them freely.

Needed when a server holds per client state in memory, a WebSocket connection or an in process session. It works, but it fights horizontal scaling: adding or removing a server reshuffles who owns which client, and a single server failure drops every client pinned to it.

Stateless servers avoid the problem entirely, which is why statelessness is the default target at scale.

**Shows up in:** [[scaling-stages]], [[websockets-and-sse]].
