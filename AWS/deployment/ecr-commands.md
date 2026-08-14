# ECR Commands

> [!tldr]
> The three commands that move an image into Amazon Elastic Container Registry: log in, delete the old tag, push the new one.

---

## Setting the variables

```makefile
AWS_DEFAULT_REGION := us-east-1
ECR_REGISTRY = <account-id>.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/<repository-name>
```

The registry hostname is built from your 12 digit AWS account ID and the region, with the repository name on the end. Because it is derived rather than typed, the region variable is the only thing you change to point at another region.

---

## Log in

Docker has to be running for this.

```bash
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} \
  | docker login -u AWS --password-stdin ${ECR_REGISTRY}
```

`get-login-password` prints a short lived token, and the pipe hands it straight to `docker login` through `--password-stdin`.

> [!tip] Why the pipe matters
> Passing the token as a command line argument would put a live credential into your shell history and into the process list, where any other user on the machine can read it. Piping it into stdin keeps it out of both. Worth being able to explain, because it is the same reasoning behind every other "do not put secrets in argv" rule.

---

## Delete the latest tag

```bash
aws ecr batch-delete-image \
  --region ${AWS_DEFAULT_REGION} \
  --repository-name <repository-name> \
  --image-ids imageTag=latest
```

---

## Push

```bash
docker push ${ECR_REGISTRY}:latest
```

---

> [!warning] Two things were redacted from the original notes
> The real 12 digit AWS account ID and the real repository name have been replaced with `<account-id>` and `<repository-name>`. An account ID is not a secret in the way a key is, but it identifies the account to anyone probing it, and the repository name named an internal service. Neither belongs in a repo other people clone.
