# Infrastructure as Code (IaC)

> [!tldr]
> Servers, networks and permissions are described in files kept in version control, instead of being clicked together in a web console. The files are the definition, so an environment can be rebuilt from them exactly.

The clicked version has no record of what you did, no review before you did it, and no way to make staging match production other than remembering. The written version is reviewed, diffed and reverted the same way application code is.

> [!example]- A bucket, declared instead of clicked
>
> ```hcl
> resource "aws_s3_bucket" "uploads" {
>   bucket = "acme-uploads-prod"
> }
>
> resource "aws_s3_bucket_versioning" "uploads" {
>   bucket = aws_s3_bucket.uploads.id
>   versioning_configuration { status = "Enabled" }
> }
> ```
> `terraform plan` prints what it is about to change before it changes anything, which is the step the console never gave you.
> Creating the identical bucket in a second region is a copy of this block, not a second afternoon of clicking.

| | Console clicking | Infrastructure as code |
| --- | --- | --- |
| Record of the change | whatever you remember | a commit with an author and a reviewer |
| Rebuilding an environment | do it all again by hand | apply the same files |
| Staging matching production | roughly, by luck | by construction, same files with different variables |
| Undoing a mistake | remember the old value | revert the commit |

Terraform works across clouds and uses its own configuration language. CloudFormation is AWS only and ships with the platform. Either way the useful property is the same: the desired state exists as text somewhere.

> [!warning] Drift is the failure mode to know
> Someone changes a setting by hand and the files no longer describe reality, so the next apply either reverts their fix or fails confusingly. [[gitops]] answers this by having a controller reconcile continuously rather than only when a human runs the tool.

**Shows up in:** [[designing-the-four-layers]], [[pipelines]], [[multi-region-cart]].
