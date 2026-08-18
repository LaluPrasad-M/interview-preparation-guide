# OAuth

> [!tldr]
> OAuth solves one problem: letting an app access your data on another service, without ever seeing your password for that service.

---

## The problem it solves

Delegated authorization. A third party app wants to read your Google contacts. Handing that app your Google password is the old, dangerous way, it now has full access forever, and Google has no way to grant it partial or revocable access.

OAuth replaces the password with a token scoped to exactly what was approved, for exactly as long as it was approved.

---

## The four actors

| Actor | Is |
| --- | --- |
| Resource owner | you, the person who owns the data |
| Client | the third party app requesting access |
| Authorization server | issues the token, usually the identity provider, for example Google |
| Resource server | holds the actual data and accepts the token, for example the Google Contacts API |

The client never sees your password. It redirects you to the authorization server, you approve a specific scope there, and the client receives only a token good for that scope.

---

## What OAuth does not solve

OAuth answers "can this app access this data on my behalf", not "who is this user". Using an OAuth access token to decide who logged into your own app is a common misuse, since the token only proves the app was granted some scope, not the user's identity.

That identity problem is what [[oidc]] adds on top of OAuth, a thin identity layer carrying who the user is, alongside the access token OAuth already provides.

---

## The three tokens a "log in with Google" gives you

| Token | Answers | Used for |
| --- | --- | --- |
| ID token | who is this user | logging them into your own app, it is a JWT with claims like `sub`, `email` and `name` |
| Access token | what may this app touch | calling the provider's APIs, sent as `Authorization: Bearer ...` |
| Refresh token | how do we carry on without asking again | getting a new access token when the short one expires, see [[jwt]] |

The mistake worth naming: using the access token as proof of identity.
It proves a scope was granted, not who granted it, and the ID token is the one that carries the person.

> [!tip] The line for "OAuth against OIDC"
> OAuth is an authorization framework for delegating access to resources. OIDC is an identity layer on top of it, standardising authentication through an ID token.

---

## OAuth versus JWT

| | OAuth | JWT |
| --- | --- | --- |
| What it is | a protocol, a flow between four actors | a token format, three parts and a signature |
| What it solves | delegated access to another service's data | proving a claim without a database lookup |
| Relationship | often issues a JWT as the access token | can be used with or without OAuth |

They get confused because OAuth commonly hands out a JWT as its access token, but OAuth is the handshake and JWT is just one shape the resulting token can take.

See [[oauth-token-lifecycle]] for a worked design around refreshing these tokens at scale.
