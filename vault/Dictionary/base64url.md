# Base64URL

> [!tldr]
> A URL safe version of Base64 that swaps `+` and `/` for `-` and `_`, so the encoded value can sit in a query string or URL without escaping.

Standard Base64 output like `ab+c/de=` breaks a URL, since `+` and `/` are reserved characters. Base64URL produces `ab-c_de` instead, safe to paste directly into a path or query parameter.

This is why JWTs and pagination cursors both use it: the header and payload need to travel inside a URL or an `Authorization` header untouched.

**Shows up in:** [[jwt]], [[enterprise-auth-sso]], [[api-design-fundamentals]].
