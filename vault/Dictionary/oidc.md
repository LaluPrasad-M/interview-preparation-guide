# OpenID Connect (OIDC)

> [!tldr]
> A protocol that lets a workload request a short lived identity token from a trusted issuer at run time, so no long lived credential ever sits in storage.

Built on top of OAuth 2.0's standard endpoints rather than a custom auth flow. GitHub Actions uses it to get a temporary cloud access token straight from the provider based on cryptographic trust, instead of storing a permanent cloud secret in the pipeline.

**Shows up in:** [[enterprise-auth-sso]], [[github-actions]].
