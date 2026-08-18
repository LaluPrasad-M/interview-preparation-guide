# WebSockets and Server Sent Events

> [!tldr]
> WebSockets are a two way street. SSE is a one way street where only the server pushes.

---

## The core difference

**WebSockets.** Both the client and the server can send messages to each other at any time.

**SSE.** The client opens the connection, and only the server pushes data down it.

---

## Feature comparison

| Feature | WebSockets | Server Sent Events |
| --- | --- | --- |
| Directionality | bidirectional, full duplex | one way, server to client |
| Underlying protocol | `ws://` or `wss://`, upgraded from HTTP | `http://` or `https://`, standard HTTP |
| Data types | text and binary | text only, UTF-8 |
| Connection handling | stateful, server memory per connection | a standard HTTP response kept open |
| Reconnections | manual, needs custom logic and [[exponential-backoff|backoff]] | automatic, the native `EventSource` API handles it |
| Infrastructure and proxies | complex, needs [[sticky-session|sticky sessions]] and specific load balancer config | simple, works with standard HTTP infra out of the box |
| Firewall friendly | can be blocked by strict corporate firewalls | highly compatible |
| Browser connection limit | high, usually up to 255 per domain | 6 per domain on HTTP/1.1, unlimited on HTTP/2 |

---

## The upgrade handshake

A WebSocket does not start as a WebSocket. It starts as ordinary HTTP.

**Step 1, the client asks to upgrade.**

```http
GET /ws HTTP/1.1
Upgrade: websocket
Connection: Upgrade
```

**Step 2, the server agrees.**

```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
```

That means we are no longer speaking HTTP. From now on this TCP connection is a WebSocket. The handshake ends and the socket begins.

**Step 3, bidirectional messages.** The connection is now persistent, bidirectional and stateful. The client can send at any time and so can the server.

> [!tip] Why the handshake works this way
> Firewalls allow ports 80 and 443, proxies understand HTTP, and browsers already speak it. So the connection looks like HTTP, walks through the firewall, and only then upgrades.

---

## The golden rule for choosing

**Choose WebSockets when** the user is actively interacting with the system in real time and data flies in both directions constantly. Multiplayer gaming, live typing or drawing, interactive whiteboards.

**Choose SSE when** the user is mostly consuming a live stream of data, and any actions they take can be handled by ordinary REST POST requests. Live sports scores, social feeds, LLM text streaming, notification bell updates.

---

## Picking a transport for a real time voice system

For speech to text, text to speech and live call state, choose based on the communication boundary and the streaming pattern.

| Communication | Preferred | Why | Trade off |
| --- | --- | --- | --- |
| Telephony provider to ingress | WebSocket | continuous bidirectional audio stream | connection management, reconnects |
| Ingress to STT | gRPC bidirectional streaming | efficient binary streaming, low latency | more operational complexity than REST |
| STT to orchestrator | gRPC streaming | stream partial and final transcripts | tight service coupling |
| Orchestrator to LLM | gRPC or HTTP streaming | token and response streaming | streaming error handling is harder |
| LLM to TTS | gRPC streaming | send text chunks, receive audio chunks | more complex flow control |
| TTS to ingress | gRPC streaming | low latency audio streaming | connection lifecycle management |
| Internal CRUD and config APIs | REST over HTTP | simple, debuggable, widely supported | higher overhead than gRPC |
| External client to backend real time | WebSocket | browser and mobile friendly, bidirectional | stateful connections, scaling complexity |
| Async events and decoupling | Kafka | durable, replayable, scalable | not for ultra low latency request and response |

### Recommended architecture

```text
Telephony
    | WebSocket
    v
Voice Gateway
    | gRPC streaming
    |----------> STT
    |----------> LLM / Orchestrator
    +----------> TTS
                     |
                     v
              Voice Gateway
                     |
                     v
                 Telephony
```

> [!tip] Interview takeaway
> Do not say "WebSocket for external, gRPC for internal" as a hard rule. Say "WebSocket is preferred where browser or telephony compatibility and persistent bidirectional connections matter. gRPC streaming is preferred for internal low latency service to service streams."
