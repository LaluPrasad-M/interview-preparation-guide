# Hardening

> [!tldr]
> Three things interviewers ask you to make safe: a password reset flow, an API under abuse, and a session stored in a cookie.

---

## Password reset, securely

The steps:

1. Verify the user's identity, through email or another channel.
2. Generate a secure, time limited reset token.
3. Serve a secure form to set the new password.
4. Handle errors gracefully, and log anything suspicious.

Two details carry most of the security. The token has to expire, because a reset link that works forever is a permanent spare key sitting in an inbox. And errors have to be handled the same way whether the account exists or not, since a message that says "no such user" tells an attacker which addresses are registered.

---

## Storing passwords

You never store a password. You store proof that someone knew it.

| Approach | Verdict |
| --- | --- |
| Plain text | never, one database leak is every account |
| Encrypted | no, encryption can be reversed, and whoever holds the key holds every password |
| Hashed with a salt | yes, this is the bar |
| Hashed with a slow algorithm, bcrypt or argon2 | yes, and this is what production means by hashing |

A hash cannot be reversed, so a leak gives an attacker nothing to log in with directly.
A salt is a random value stored with each password, so two people using the same password get different hashes and one cracked hash does not unlock the others.
Slow is the point: bcrypt is deliberately expensive, which makes guessing billions of candidates impractical rather than merely tedious.

> [!tip] The recall line
> Passwords are hashed, not encrypted. If you can decrypt it, so can whoever steals the key.

Note the side effect on your service: bcrypt is CPU work on the libuv thread pool, so a login storm shows up as latency everywhere, see [[event-loop-lag]].

---

## Secrets

| Never | Instead |
| --- | --- |
| Hardcoded in source | environment variables loaded at startup |
| Committed to git, even once | a secret manager, for example AWS Secrets Manager or Vault |

A secret that ever reached a git history is leaked, since rewriting history does not reach the clones and forks already out there. The fix is rotating the secret, not deleting the commit.

---

## Rate limiting

Set a threshold on how many requests a user or client may make in a given time window. It prevents abuse, blunts denial of service attacks, and keeps usage fair between callers.

| Technique | How it counts |
| --- | --- |
| Token bucket | tokens refill at a steady rate, each request spends one, so short bursts are allowed while the long run average is capped |
| Sliding window | counts requests in the trailing window, so the limit moves smoothly with time |
| Fixed window | counts requests per fixed block of time, which is simplest and allows a burst at each boundary |

That boundary burst is the reason the three differ: with a fixed window, a caller can spend its whole allowance at the end of one window and again at the start of the next, so twice the limit lands in a short space of time.

Login, one time password and password reset endpoints get the tightest limits of all.
Those are the ones worth attacking: brute force, credential stuffing with a leaked password list, or using your reset endpoint to send mail on someone's behalf.
The distributed version, one limit shared across many servers, is in [[distributed-rate-limiter]].

For retries on the client side of a limit, see [[exponential-backoff]].

---

## Session data in cookies

The risks are session theft and cookie tampering, both of which expose whatever the cookie holds.

The mitigations:

- **Encrypt and sign** the session data, so it can be neither read nor altered.
- **Set the cookie flags.** `HttpOnly` keeps JavaScript from reading it, which is what limits the damage from [[cross-site-scripting]]. `Secure` stops it travelling over plain HTTP.
- Add whatever else the case needs, such as a short expiry and rotation on privilege change.

> [!tip] The safest cookie holds an identifier, not data
> Keeping only a session ID in the cookie and the data on the server means a stolen cookie is useless once you invalidate the session. A cookie carrying the session state itself cannot be revoked that way, because the copy the attacker holds stays valid until it expires.
