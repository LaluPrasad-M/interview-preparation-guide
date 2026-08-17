# ECR Commands

> [!tldr]
> The three commands that move an image into Amazon Elastic Container Registry: log in, delete the old tag, push the new one.

---

## As a Makefile

This is how the original lives, and how it runs in CI. Note `$(VAR)` for expansion and `:=` for assignment, both Make syntax rather than shell.

```makefile
AWS_DEFAULT_REGION := us-east-1
ECR_REGISTRY := <account-id>.dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com/<repository-name>

# Login to AWS registry (must have docker running)
login:
	aws ecr get-login-password --region $(AWS_DEFAULT_REGION) \
	  | docker login -u AWS --password-stdin $(ECR_REGISTRY)

# Delete latest image from ecr
clean:
	aws ecr batch-delete-image --region $(AWS_DEFAULT_REGION) \
	  --repository-name <repository-name> --image-ids imageTag=latest

# Push the image to ecr
push:
	docker push $(ECR_REGISTRY):latest
```

The registry value is a hostname plus a repository path. `docker login` only needs the hostname part, and gives you the whole registry when you authenticate against it, while `docker push` needs the full path plus a tag.

---

## As shell commands

These are the same three commands to run by hand. `export` matters here, since the later commands read the variables from the environment.

```bash
export AWS_DEFAULT_REGION=us-east-1
export ECR_REGISTRY=<account-id>.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/<repository-name>

# log in, docker must be running
aws ecr get-login-password --region "${AWS_DEFAULT_REGION}" \
  | docker login -u AWS --password-stdin "${ECR_REGISTRY}"

# delete the latest tag
aws ecr batch-delete-image \
  --region "${AWS_DEFAULT_REGION}" \
  --repository-name <repository-name> \
  --image-ids imageTag=latest

# push
docker push "${ECR_REGISTRY}:latest"
```

---

## Why the login pipes into stdin

`get-login-password` prints a short lived token, and the pipe hands it straight to `docker login` through `--password-stdin`.

> [!tip] Never pass a token as an argument
> A command line argument lands in your shell history and is visible in the process list to anyone else on the machine. Piping into stdin keeps it out of both. The same reasoning is behind every other "do not put secrets in argv" rule.

---

> [!warning] Two things were redacted from the original notes
> The real 12 digit AWS account ID and the real repository name are replaced with `<account-id>` and `<repository-name>`. An account ID is not secret the way a key is, but it identifies the account to anyone probing it. The repository name named an internal service. Neither belongs in a repo other people clone.
