# JSON Web Key Set (JWKS)

> [!tldr]
> A public page where an identity provider publishes the keys needed to check its tokens, conventionally at `/.well-known/jwks.json`. Anyone can fetch it, because it holds public keys only.

It exists so that verifying a token needs no phone call. The provider signs a JSON Web Token (JWT) with a private key nobody else has, and your gateway checks the signature with the matching public key from this endpoint.

A gateway fetches the set once, keeps it in memory for something like 24 hours, and from then on verifies every request locally with zero network calls. Millions of requests, no round trip to the identity provider.

The `kid` field, short for key ID, is what makes rotation work. Each key in the set has one, and each token's header names the key it was signed with.

```json
{ "keys": [
  { "kid": "2026-a", "kty": "RSA", "n": "...", "e": "AQAB" },
  { "kid": "2026-b", "kty": "RSA", "n": "...", "e": "AQAB" }
] }
```

The provider can start signing with `2026-b` while tokens signed by `2026-a` are still valid, because both keys sit in the set until the old ones expire. Nothing breaks mid rotation, and nobody has to redeploy.

| | Shared secret, HS256 | Public key, RS256 with JWKS |
| --- | --- | --- |
| Verifier needs | the same secret that signs tokens | only the public key |
| Rotation | coordinate every service at once | publish the new key, tokens name their own |
| Risk if a verifier leaks its config | attacker can mint valid tokens | attacker can verify tokens, which is harmless |

> [!warning] Cache it, but honour failures carefully
> Fetching the set on every request makes the identity provider a hard dependency on your hot path. Caching it for too long means a compromised key stays trusted, so the usual answer is a long cache plus a forced refresh when an unknown `kid` shows up.

**Shows up in:** [[enterprise-auth-sso]], [[api-gateway]].
