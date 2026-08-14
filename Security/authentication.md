# Authentication

> [!tldr]
> Authentication answers "who are you". It verifies the identity of a user, device or system, so the thing asking for access is who it claims to be.

Not to be confused with [[authorization]], which answers "what are you allowed to do". Interviewers ask for that distinction constantly, usually as the first question of the round.

---

## The methods

| Method | Is |
| --- | --- |
| Username and password | the baseline, and the weakest on its own |
| Token based | a token issued after login and sent with each request |
| Certificate based | the client proves identity with a certificate rather than a secret it types |
| Single Sign-On (SSO) | one login grants access across several systems |
| Biometric | fingerprint or eye scanners, facial or voice recognition |
| Two factor (2FA) | a password plus one more proof, usually an OTP |
| Multi factor (MFA) | two or more proofs, for example a password, a fingerprint scan and a security question |

The distinction between 2FA and MFA is just the count: 2FA is exactly two factors, MFA is two or more. So 2FA is a kind of MFA.

---

## Access tokens

An access token is issued by the authentication server after a successful login. It grants access to protected resources.

The flow is short enough to recite:

1. The client authenticates once.
2. The server issues an access token.
3. The client includes that token with every request.
4. The server validates the token and authorises the operation.

The reason this is worth doing is that step 4 needs no lookup of the user's password and, with a self contained token, often no lookup at all. The token carries the proof, which is what lets the same token be checked by many services. See the microservices section in [[authorization]].
