# Encryption

> [!tldr]
> Symmetric encryption uses one key for both directions and is fast. Asymmetric uses a public key to encrypt and a private key to decrypt. It is slower, and real systems use both.

---

## The comparison

| | Symmetric | Asymmetric |
| --- | --- | --- |
| **Keys** | the same key encrypts and decrypts | a public key encrypts, a private key decrypts |
| **Speed** | faster | slower |
| **The hard part** | distributing the key securely | none for distribution, the public key can be published |
| **Used for** | securing data in transit and at rest | key exchange and digital signatures |

---

## Why both exist

Symmetric encryption is fast but has a chicken and egg problem: both sides need the same secret key, and sending it over the network is exactly the thing you were trying to protect.

Asymmetric encryption solves distribution, since the public key can be handed to anyone, but it is far too slow for bulk data.

So the standard arrangement uses each for what it is good at. Asymmetric encryption performs the key exchange, agreeing a fresh symmetric key, and everything after that is encrypted symmetrically with that key. TLS works this way, which is worth naming, because "how does HTTPS work" is really the same question in different words.

---

## Digital signatures run it backwards

Signing uses the private key to produce the signature and the public key to verify it, which is the reverse of encrypting. That reversal is what makes it proof of origin: only the holder of the private key could have produced something the matching public key validates.

Encryption at rest for stored objects, including who holds the key, is in [[s3-security]].
