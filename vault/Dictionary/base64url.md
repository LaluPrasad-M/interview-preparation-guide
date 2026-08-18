# Base64URL (URL Safe Base64)

> [!tldr]
> A version of Base64 that swaps the two characters a URL would choke on, so the encoded value can sit in a link or a header exactly as it is.

Base64 turns any bytes into text using 64 safe characters, `A` to `Z`, `a` to `z`, `0` to `9`, plus `+` and `/`. That lets binary data travel through channels that only accept text.

The problem is that two of those 64 characters already mean something in a Uniform Resource Locator (URL). Base64URL keeps everything else and replaces just those.

| Position | Standard Base64 | Base64URL | Why it had to change |
| --- | --- | --- | --- |
| 62nd character | `+` | `-` | in a query string `+` is read as a space |
| 63rd character | `/` | `_` | `/` starts a new path segment |
| Padding | `=` at the end | dropped entirely | `=` separates a parameter from its value |

> [!example]- The first part of every JSON Web Token
> The header `{"alg":"HS256","typ":"JWT"}` encodes to `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`.
> That string survives being pasted into a URL, an `Authorization` header or a cookie without anything escaping or re-encoding it.
> A JSON Web Token (JWT) is three such chunks joined by dots, so all three have to be URL safe or the token breaks in transit.

Pagination cursors use it for the same reason: the cursor is really a small blob of state, and it has to ride along in `?cursor=...` untouched.

**Shows up in:** [[jwt]], [[enterprise-auth-sso]], [[api-design-fundamentals]].
