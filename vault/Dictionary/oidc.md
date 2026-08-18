# OpenID Connect (OIDC)

> [!tldr]
> A thin identity layer on top of OAuth 2.0. OAuth answers "is this caller allowed to do that", OIDC adds "and here is who they actually are", in a signed token you can verify yourself.

The addition is the ID token, a JSON Web Token (JWT) describing the user or workload: who issued it, who it is about, when it expires. It is signed by the issuer, so a verifier checks it against the issuer's [[jwks]] and needs no call back to the provider. See [[oauth]] for the flows underneath.

The same protocol covers two situations that look unrelated at first.

| | Signing a person in | Giving a workload an identity |
| --- | --- | --- |
| Who asks for the token | a browser app, on the user's behalf | a build job or a pod, for itself |
| What it proves | this is the user, verified by the provider | this is that repository's workflow, on that branch |
| Replaces | your own password table | a long lived secret in configuration |
| Example | "Sign in with Google" | GitHub Actions requesting a temporary AWS role |

That second column is the one worth remembering, because it removes stored credentials entirely. GitHub Actions asks its issuer for a short lived token describing the exact workflow and branch, AWS is configured to trust that issuer for that repository, and it hands back temporary credentials. No permanent cloud key ever sits in the pipeline to be leaked, and access dies with the job.

> [!tip] The interview line is the one word difference
> OAuth 2.0 is about authorization, which is access. OIDC is about authentication, which is identity. Building login on plain OAuth is the common mistake, because an access token tells you a caller has permission without reliably telling you who they are.

**Shows up in:** [[enterprise-auth-sso]], [[oauth]], [[github-actions]].
