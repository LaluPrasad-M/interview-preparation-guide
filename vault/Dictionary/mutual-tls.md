# Mutual TLS (mTLS)

> [!tldr]
> Both sides of a connection present a certificate, so the client proves its identity to the server just as the server proves its identity to the client.

Normal TLS only proves the server is who it claims to be. mTLS closes the other direction too, which is why a zero trust internal network uses it between services: a gateway can cryptographically prove it is the gateway, so a downstream service does not have to trust a spoofable header instead.

A service mesh usually issues and rotates these certificates automatically, so individual services do not manage them by hand.

**Shows up in:** [[enterprise-auth-sso]], [[api-gateway]], [[kubernetes-basics]].
