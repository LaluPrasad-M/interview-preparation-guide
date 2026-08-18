# Enterprise Authentication and SSO

> [!tldr]
> Authenticate once, sign a token with a private key that never leaves the vault, and let every service verify it in RAM with the public key. Zero network hops on the critical path.

---

## The problem

You are building the architecture for a large company with 50 microservices and 10 frontend applications.

If every microservice checks the user's password, your database melts and your security is vulnerable, with passwords scattered everywhere.

And if the user logs into one app, they should not have to type their password again in another. That is the lack of single sign on.

**The objective.** Build a centralised identity provider that authenticates the user once, issues a cryptographically secure token, and lets all 50 microservices mathematically verify identity in zero network hops without ever seeing a password.

---

## Functional requirements

**Authenticate.** Validate credentials, email and password plus MFA.

**Authorize.** Issue standardised access and refresh tokens via OAuth 2.0.

**Validate.** Let downstream services or the gateway securely validate tokens.

**Revoke.** Provide a kill switch to immediately invalidate a compromised token, for example if a laptop is stolen.

---

## Non functional requirements

| Dimension | Requirement |
| --- | --- |
| Scale and traffic | extremely read heavy. A user logs in once a week, but their token is validated on every single API request |
| Performance | token validation under 1 millisecond. We cannot afford an HTTP call to the auth service per request |
| Availability against consistency | absolute high availability. If the auth service goes down, the entire company goes down |
| Concurrency | safe handling of concurrent token refreshes |
| Edge cases | the revocation trap, because stateless tokens cannot be inherently revoked, and key rotation when signing keys expire |

---

## The architecture

```text
======================= PHASE 1: THE LOGIN DANCE (OAUTH 2.0) ==========================

      +-------------------------------------------+
      |          CLIENT APP (React / iOS)         |
      +---------------------+---------------------+
                            | 1. Redirect to Login UI
                            | 2. POST /v1/auth/login (User/Pass)
                            v
      +-------------------------------------------+  3. Verify credentials
      |         CENTRAL AUTHENTICATION IDP        +--------+
      |        (Node.js / Go OAuth2 Server)       |        |
      +------+------------------------------+-----+        v
             |                              |     +--------------------+
             | 4. Sign JWT via RSA private  |     | POSTGRESQL         |
             |    key (stored in KMS)       |     | (Users & passwords)|
             v                              |     +--------------------+
  +-------------------------+               | 5. Save refresh token
  |  KMS / VAULT            |               v
  | (Holds the private key) |       +--------------------+
  +-------------------------+       |   REDIS CLUSTER    |
                                    | (Refresh tokens &  |
                                    |  revocation list)  |
                                    +--------------------+
             6. Return { Access_Token (JWT), Refresh_Token } to client

===================== PHASE 2: ZERO-LATENCY VALIDATION ===================

      +-------------------------------------------+
      |          CLIENT APP (React / iOS)         |
      +---------------------+---------------------+
                            | 7. GET /v1/orders
                            | Header: Authorization: Bearer <JWT>
                            v
      +-------------------------------------------+  8. Download public keys (JWKS)
      |      API GATEWAY (Kong / Nginx)           |  (Cached for 24 hours)
      |      (The global enforcement point)       +---------> AUTH SERVICE
      +---------------------+---------------------+
                            | 9. Mathematically verify JWT signature locally (0ms)
                            | 10. Check Redis revocation blocklist (2ms)
                            | 11. Strip JWT, inject internal headers (X-User-ID: 123)
                            v
      +-------------------------------------------+
      |         INTERNAL MICROSERVICES            |
      |   (Order service, billing service, etc.)  |
      +-------------------------------------------+
```

---

## Phase 1: authentication and token generation

**1. The request.** The user enters credentials and the client sends `POST /login`.

**2. Database verification.** The auth service hashes the password using bcrypt or Argon2 and verifies against PostgreSQL.

**3. Token generation.** The service creates a JWT with a payload containing the user ID, roles, and an expiry, for example 15 minutes.

**4. The cryptographic signature.** The service signs that payload using an asymmetric RSA private key. Only the auth service holds the private key, so no one else can forge this token.

**5. State storage.** The JWT is stateless and not saved. But the service generates a refresh token, a random opaque string with a 30 day lifespan, hashes it, and saves it in Redis or Postgres.

**6. Return.** The client receives both tokens.

---

## Phase 2: decentralised validation

If the gateway makes an HTTP call to the auth service to validate the JWT on every request, the auth service crashes from the load.

**7. The API call.** The client sends `GET /orders` with the JWT in the header.

**8. The [[jwks|JWKS]] cache.** The gateway periodically calls `GET /.well-known/jwks.json` to download the public keys, and caches them in local RAM.

**9. Zero hop validation.** The gateway uses the cached public key to mathematically verify the signature. If the maths checks out, the gateway knows the token was created by the auth service and has not been tampered with. Under 1 millisecond and zero network calls.

**10. The handoff.** The gateway extracts the `user_id`, drops the JWT completely, and forwards the request internally with a trusted header `X-User-ID: 123`.

---

## API design, standardised [[oidc|OIDC]]

Follow RFC standard OAuth 2.0 endpoints. Do not invent your own authentication routing in an interview.

### Token endpoint

**POST** `/v1/oauth/token`

```json
{
  "grant_type": "password",
  "client_id": "web_app_01",
  "username": "user@example.com",
  "password": "SecurePassword123"
}
```

```json
{
  "access_token": "eyJhbGciOiJSUzI1Ni...",
  "token_type": "Bearer",
  "expires_in": 900,
  "refresh_token": "ref_99a8b7c6..."
}
```

### The JWKS endpoint

**GET** `/.well-known/jwks.json` returns the JSON web key set, the public keys used by the gateway to verify tokens.

---

## Database design

**Table `users`, PostgreSQL.** `id` UUID primary key, `email` VARCHAR with a unique index, `password_hash` VARCHAR because you never store plaintext, `mfa_secret` VARCHAR nullable, and `role` VARCHAR.

**Table `oauth_clients`, PostgreSQL.** `client_id` VARCHAR primary key, `client_secret_hash` VARCHAR, and `allowed_redirect_uris` JSONB.

**Refresh tokens, Redis.** Key `refresh_token:ref_99a8b7c6`, value `{ "user_id": "123", "client_id": "web_app_01" }`, [[ttl|TTL]] 30 days.

Why Redis? Because querying Postgres to validate a refresh token during a high traffic renewal spike is too slow.

---

## Trade offs

### JWTs against opaque tokens

**The dilemma.** With opaque tokens, random strings, the gateway must query Redis on every single request to check validity. That causes massive Redis load and adds 5 ms to every call.

**The solution.** Use asymmetrically signed JWTs, validated in CPU memory at zero milliseconds.

**The trap.** JWTs cannot be revoked natively. If an attacker steals a JWT, it is valid until it expires. We trade immediate revocability for massive global scalability. See [[jwt]] for the underlying mechanics.

### Mitigating the unrevocable JWT

Make the JWT lifespan extremely short, 15 minutes. If an attacker steals it, they have 15 minutes.

To prevent the user logging in every 15 minutes, the client automatically sends the refresh token, which has a 30 day lifespan, to the auth service in the background to get a new JWT. Because the refresh token hits the auth service database, we can revoke it instantly.

---

## Cryptographic key management

### How the private key is generated

**The naive approach.** A developer runs an `openssl` command locally, saves `private.pem`, and hardcodes it into source or drops it into `.env`.

Why it fails: if that file is committed to source control, or the server is compromised, the private key is stolen and the attacker can forge valid tokens for any user.

**The enterprise approach.** The auth service does not generate or hold the key in its own codebase.

1. **The vault.** Use a key management service.
2. **Generation.** An infrastructure script instructs the KMS to generate an asymmetric RSA-256 key pair. The private key is generated inside a hardware security module.
3. **The absolute rule.** The private key never leaves the vault. The KMS physically prevents anyone, even root admins, from exporting it.
4. **Signing.** When a user logs in, the auth service constructs the JSON payload and sends it over the internal network to the KMS. The KMS signs it using the locked private key and returns the signature.
5. **Why this is bulletproof.** Even if an attacker fully compromises the auth service container and dumps RAM, they cannot steal the private key, because the container never possessed it.

### How the gateway verifies

Every identity provider must expose a public unauthenticated endpoint containing its public keys, the JWKS endpoint at `/.well-known/jwks.json`.

```json
{
  "keys": [
    {
      "kty": "RSA",
      "alg": "RS256",
      "use": "sig",
      "kid": "key-2026-08",
      "n": "vXf_abc123...",
      "e": "AQAB"
    }
  ]
}
```

The verification flow at the gateway:

1. **Read the header.** Decode the JWT header, which is [[base64url|Base64Url]] encoded, not encrypted.
2. **Find the `kid`.** Look for which key signed it: `{"alg": "RS256", "kid": "key-2026-08"}`.
3. **Check the local cache.** Does the gateway have the public key for that `kid`?
4. **Fetch if missing.** If not, make a quick GET to the JWKS endpoint, download the keys, and cache them in RAM for 24 hours.
5. **The maths.** Use the cached public key to run an RSA verification against the signature.
6. **The result.** If it returns true, the gateway is mathematically certain the JWT was signed by the private key locked in the vault. It strips the JWT, injects the trusted `X-User-ID`, and routes internally.

Using a vault for the private key and the standard JWKS endpoint for the public key completely decouples the gateway from the auth service, achieving zero network hop validation with strong security.

---

## Follow up questions

### Immediate revocation

**Q.** JWTs are valid for 15 minutes. What if an employee is fired and we need to revoke access immediately?

**A.** A distributed denylist in Redis. When an admin clicks revoke, the auth service publishes the `user_id` or the JWT `jti` to a Redis set with a TTL of 15 minutes.

The gateway, after validating the signature in RAM, makes a 1 millisecond check against that denylist. If the token is listed, it blocks the request. After 15 minutes the JWT naturally expires and Redis deletes the entry to free RAM. Immediate revocation without permanently bloating the database.

### Key rotation without logging everyone out

**Q.** Cryptographic keys get compromised. How do you rotate without logging out millions of users simultaneously?

**A.** Use the `kid` field in the JWT header.

1. The auth service generates a new key pair, key B, and adds the new public key to `/jwks.json` alongside the old key A.
2. It immediately starts signing all new JWTs with key B.
3. The gateway sees a request whose header says `kid: Key_A`, and uses key A from its cache to validate.
4. Because both public keys are cached, old and new tokens validate simultaneously. Once the 15 minute expiry window passes, all key A tokens expire naturally and we safely delete key A.

### Spoofing the internal header

**Q.** If the gateway passes `X-User-ID: 123` internally, what stops a compromised internal container from spoofing that header and making requests as the CEO?

**A.** The classic zero trust problem. We cannot trust HTTP headers, even internally. Implement a [[service-mesh|service mesh]] with [[mutual-tls|mutual TLS]]. The gateway uses mTLS to authenticate its identity to downstream services, and those services are configured to only accept the `X-User-ID` header if the request cryptographically proves it originated from the gateway, rejecting spoofed requests from rogue containers.
