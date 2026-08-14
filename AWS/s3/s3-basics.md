# S3 Basics

> [!tldr]
> Amazon Simple Storage Service stores data as objects inside buckets, not as files inside folders. It is object storage, which is why it scales without limit and why it has no real directories.

---

## What it is

S3 lets you store and retrieve large amounts of data securely and at scale. Unlike a traditional file system or block storage, it stores data as **objects** within **buckets**.

| Feature | What it means |
| --- | --- |
| Scalability | virtually unlimited storage capacity |
| Durability and availability | designed for 99.999999999% durability, eleven nines |
| Security | encryption, access control, IAM policies |
| Cost effective | several storage classes, so you pay for the access pattern you actually have |
| Access control | IAM roles, policies and ACLs for fine grained access |
| Event driven | notifications and triggers, usually into AWS Lambda |

Eleven nines of durability is worth translating: store ten million objects and you would expect to lose one about every ten thousand years. That is why S3 is treated as the safe place to put things.

---

## How it works

Every object has three parts:

| Part | Is |
| --- | --- |
| Data | the actual content |
| Metadata | descriptive attributes |
| Key | the unique identifier within the bucket |

A bucket is like a folder, but **flat**. There are no nested directories. A key that looks like `logs/2026/08/app.log` is one long name containing slashes, not three folders, and the console only draws it as a tree to be helpful.

---

## Storing a file, start to finish

1. Create a bucket. The name has to be globally unique, across every AWS account in the world.
2. Upload an object into it.
3. Assign permissions to control access.
4. Retrieve it by URL or API request.

---

## Using it from the console

**Create a bucket.** Go to the AWS Management Console, navigate to S3, click Create Bucket, enter a unique name, choose a region, configure versioning, encryption and public access, then create it.

**Upload files.** Open the bucket, click Upload, select files, set the storage class and encryption, then upload.

---

## Using it from code

A public object has a URL:

```text
https://s3.amazonaws.com/bucket-name/object-name
```

From the CLI:

```bash
aws s3 cp s3://bucket-name/object-name local-file
```

Or through the SDKs, which exist for Node.js, Python, Java and the rest.

> [!warning] The bucket name is global
> Bucket names are unique across all of AWS, not just your account, which is why every obvious name is taken and why a name can leak information. A bucket called `acme-payroll-backups` tells anyone who guesses it that it exists, even if they cannot read it.

Storage classes are in [[storage-classes]], access control and encryption in [[s3-security]], automatic transitions in [[s3-lifecycle]], and triggers in [[s3-events]].
