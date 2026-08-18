# Security

> [!tldr]
> Index for everything under `Security/`. Authentication is who you are, authorization is what you may do, hardening is the practical defences, encryption is how data is protected in transit and at rest.

---

## Notes

| Note | Covers |
| --- | --- |
| [[authentication]] | the seven methods, access tokens, and the four step token flow |
| [[authorization]] | role, attribute and rule based access control, permission tickets, microservices, least privilege |
| [[hardening]] | password reset, rate limiting with three algorithms, session data in cookies |
| [[encryption]] | symmetric against asymmetric, why real systems use both, digital signatures |
| [[jwt]] | the three parts, the signature maths, the end to end flow, and the four standard questions |
| [[webhook-signatures]] | HMAC, the raw body trap, timing attacks, replay attacks |
| [[cross-site-scripting]] | the attack and the defences |

---

## Filed elsewhere

| Note | Where | Why there |
| --- | --- | --- |
| [[s3-security]] | `Cloud/aws/s3/` | AWS specific: bucket policies, ACLs, the four encryption options |
| [[oauth-token-lifecycle]] | `Design/worked/systems/` | a worked design for refreshing tokens, not the auth mechanism itself |
| [[webhook-delivery]] | `Design/worked/systems/` | the delivery design; this folder covers verifying the signature, not sending it |
| [[webhook-ingestion]] | `Design/worked/systems/` | the ingestion design; same split as delivery above |
