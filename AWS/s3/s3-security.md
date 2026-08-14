# S3 Security

> [!tldr]
> Four ways to control who gets in, and four ways to encrypt what is inside. The interview question is usually which mechanism belongs at which level.

---

## Access control

| Mechanism | Works at the level of | Use it for |
| --- | --- | --- |
| IAM policies | a user or role | what a person or service is allowed to do, across AWS |
| Bucket policies | one bucket | who may touch this bucket, including accounts other than yours |
| Access Control Lists (ACLs) | an object or bucket | granting permissions to specific AWS accounts. The older mechanism |
| Public Access Block | account or bucket | preventing accidental public exposure, whatever the other three say |

The distinction that matters: an **IAM policy** is attached to the identity asking, and a **bucket policy** is attached to the thing being asked for. When you need to grant access to another AWS account, the bucket policy is the one that can express it.

**Public Access Block is the seatbelt.** It overrides the rest, which is exactly why it exists. Most published S3 leaks were a bucket policy or ACL someone loosened for a quick test and never tightened, and this setting makes that mistake unavailable.

---

## Encryption

**Server side encryption (SSE).** AWS encrypts the data before storing it.

| Option | Who holds the key |
| --- | --- |
| SSE-S3 | AWS, managed entirely for you |
| SSE-KMS | AWS Key Management Service, so you control the key policy and get an audit trail of key use |
| SSE-C | you. You send the key with each request and AWS uses it without keeping it |

**Client side encryption.** You encrypt the data before it leaves your machine, so AWS only ever sees ciphertext.

---

## Choosing between them

SSE-S3 is the default answer and takes no work. SSE-KMS is the answer when you need to say who may decrypt and to prove later who did. SSE-C and client side encryption both exist for the case where AWS must never hold the key, and the cost is that key management becomes entirely your problem, including the part where losing the key destroys the data.

> [!tip] The one line worth remembering
> Encryption at rest protects against someone getting the disk. It does nothing about someone with valid credentials, which is what the access control table above is for. Interviewers like to hear those treated as separate problems.
