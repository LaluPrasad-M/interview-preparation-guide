# JWKS (JSON Web Key Set)

> [!tldr]
> A public, unauthenticated endpoint, conventionally `/.well-known/jwks.json`, where an identity provider publishes the public keys needed to verify its tokens.

A gateway fetches this once, caches it in RAM for something like 24 hours, and from then on verifies every JWT signature locally using the cached key, with zero network calls per request. The `kid` field in the token header says which cached key to use, which is what makes key rotation possible without breaking already-issued tokens.

**Shows up in:** [[enterprise-auth-sso]], [[api-gateway]].
