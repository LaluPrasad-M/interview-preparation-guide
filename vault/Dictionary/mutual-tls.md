# Mutual Transport Layer Security (mTLS)

> [!tldr]
> Both ends of a connection present a certificate, so the client proves who it is to the server just as the server already proves who it is to the client.

Ordinary Transport Layer Security (TLS) is one directional. Your browser checks that the certificate really belongs to the bank, and the bank has no idea who you are until you log in. mTLS closes the other half, and it does it at the connection layer, before any application code runs.

| | Standard TLS | Mutual TLS |
| --- | --- | --- |
| Server proves identity | yes, with its certificate | yes |
| Client proves identity | no, not at this layer | yes, with its own certificate |
| Identity comes from | later, a password or a token | the certificate itself, at handshake time |
| Typical use | public websites | service to service traffic inside a network |

The reason it matters internally is that headers can be forged. A downstream service that trusts `X-Called-By: api-gateway` trusts a string anyone inside the network could send. With mTLS the caller has to hold a private key, so identity is proven cryptographically instead of asserted.

Managing certificates for every service by hand is the obvious objection, and it is why this usually arrives with a [[service-mesh]]. The mesh issues a certificate per service, rotates it every few hours, and the application never sees any of it.

> [!tip] This is what zero trust means in practice
> Being inside the network stops counting as proof of anything. Every hop authenticates, so one compromised pod cannot call whatever it likes just because it is on the same subnet.

**Shows up in:** [[enterprise-auth-sso]], [[api-gateway]], [[kubernetes-basics]], [[request-lifecycle]], [[prep-checklist]].
