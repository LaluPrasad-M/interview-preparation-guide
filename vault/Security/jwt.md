# JSON Web Tokens

> [!tldr]
> A JWT is a self contained VIP pass. The server does not look up a database to verify you, because the token mathematically proves it is legitimate.

---

## The problem JWT solves

In the old model, when you logged in the server created a session ID such as `#999`, saved `#999 = Rahul` in its database, and gave your browser the ID. Every time you clicked a button the server had to pause and query the database: who is `#999`?

With millions of users, that database lookup on every request becomes a bottleneck.

JWT solves this by being **stateless**.

---

## How it works mathematically

A JWT is a long string divided by two periods: `xxxxx.yyyyy.zzzzz`.

| Part | Name | Holds |
| --- | --- | --- |
| `xxxxx` | header | which algorithm was used, usually HMAC SHA-256 |
| `yyyyy` | payload | the actual data, for example user ID and expiration time |
| `zzzzz` | signature | the cryptographic lock that makes the token trustworthy |

> [!warning] The header and payload are not encrypted
> They are Base64 encoded, which is just a format computers read easily. Anyone on the internet can decode them and read your user ID.

The magic is in the signature. The server takes the visible header, the visible payload, and a secret key only the server knows, and hashes them together.

```text
Signature = HMACSHA256(
    Base64UrlEncode(Header) + "." + Base64UrlEncode(Payload),
    SecretKey
)
```

Because the server alone knows the secret key, a hacker cannot alter the payload, for example changing `User=Rahul` to `User=Admin`, and generate a matching signature.

---

## The end to end flow

**1. Client logs in.** The one time we hit the database. You enter username and password, the server checks the database, and if correct it is ready to issue the pass.

**2. Server computes the JWT.** Math, not memory. The server builds header and payload, grabs its secret key, runs the equation to generate the signature, combines all three parts and sends the JWT to the client. The server does not save this token anywhere.

**3. Client stores the token.** Usually in an HttpOnly cookie or in local storage.

**4. Client makes an API request.** It sends `GET /profile` and attaches the token in the HTTP headers as `Authorization: Bearer xxxxx.yyyyy.zzzzz`.

**5. Server validates the token.** It splits the token into three parts, takes the header and payload, combines them with its own secret key, and recomputes the equation.

**6. Access granted.** If the newly calculated signature matches the one attached to the token, the server knows it issued this token and it has not been tampered with. Zero database calls were made.

---

## Common interview questions

| Question | The standard answer |
| --- | --- |
| Can I put sensitive data like a password in the payload? | Absolutely not. The payload is Base64 encoded, not encrypted. Anyone who intercepts the token can paste it into a decoder and read it. Only put non sensitive identifiers such as `user_id` or `role`. |
| How do you log a user out if the server does not store the token? | This is the biggest flaw of JWT. Being stateless, the server cannot delete the token on its end. Standard practice is for the client to delete the token. For strict security you implement a server side blacklist of revoked tokens, which reintroduces the database bottleneck you were trying to avoid. |
| What happens if the secret key is leaked? | A catastrophic breach. The attacker can generate valid signatures and mint their own admin tokens. You must rotate the secret key immediately, which invalidates every JWT in existence and forces all users to log in again. |
| Why do we need an expiration time (`exp`)? | Because we cannot easily revoke them, JWTs must have a short lifespan, for example 15 minutes. If a token is stolen the attacker has only that window before the math considers it invalid. |
