# Request Lifecycle

> [!tldr]
> What actually happens between typing a URL and seeing a response: DNS, then TCP, then TLS, then one HTTP request over that connection. The question sounds basic and is used to check whether you know the layers or just the vocabulary.

---

## The URL, taken apart

```text
https://api.example.com/users/1?active=true

scheme  https
host    api.example.com
path    /users/1
query   ?active=true
```

---

## Step 1: DNS resolves the name to an IP

Machines route by IP address, not by name, so the name has to be turned into an address first.

The lookup checks caches before asking anyone: browser cache, then the operating system cache, then the router, then the configured resolver.

DNS is read heavy, cached aggressively at every one of those layers, and only eventually consistent.
That is why a record change takes a while to be seen everywhere, and why [[ttl|TTL]] on a DNS record matters during a migration.

---

## Step 2: TCP opens a connection

A TCP connection is identified by four values, the source IP, source port, destination IP and destination port.
Two different browser tabs talking to the same server differ only in source port.

The handshake is three messages: `SYN`, then `SYN-ACK`, then `ACK`.

TCP is used here because HTTP needs delivery that is reliable, ordered, and retransmitted when a packet is lost.

---

## Step 3: TLS makes it HTTPS

TLS runs on top of the TCP connection, after the handshake above, and gives three things:

| Guarantee | Means |
| --- | --- |
| Confidentiality | the bytes are encrypted, so a network observer sees noise |
| Integrity | tampering is detectable, the data arrives as it was sent |
| Authentication | the server proves it is who the certificate says it is |

The server certificate is mandatory.
A client certificate is optional and rare outside service to service calls, which is what [[mutual-tls|mTLS]] adds.

---

## Step 4: the HTTP request, then the response

```text
GET /users/1 HTTP/1.1
Host: api.example.com
Authorization: Bearer <token>
```

HTTP is stateless.
Each request carries everything needed to serve it, which is why the token is attached every time rather than remembered from login, see [[jwt]].

On the server side the request usually hits a load balancer, gets routed to a backend instance, and that instance authenticates, validates, and talks to its database, cache and dependencies before replying.

```text
200 OK
Content-Type: application/json

{ "id": 1, "name": "Rahul" }
```

The response travels back over the same TCP connection, which stays open for reuse thanks to keep alive, so the next request skips steps 1 to 3 entirely.

---

## The layering, in one column

```text
HTTP
TLS
TCP
IP
```

> [!tip] The one line answer
> The browser resolves DNS to an IP, opens a TCP connection, performs a TLS handshake for HTTPS, sends an HTTP request over it, and reads the HTTP response back.

---

## TCP against UDP

| | TCP | UDP |
| --- | --- | --- |
| Delivery | reliable, retransmits lost packets | best effort, packets can vanish |
| Order | preserved | not preserved |
| Connection | established first | none, just send |
| Used by | HTTP and HTTPS, databases, APIs | video streaming, gaming, DNS queries |

> [!tip] The recall line
> TCP trades speed for reliability, UDP trades reliability for speed.
