# Infrastructure State Management

Infrastructure state is built up by `.json` files stored in a disk somewhere.

This disk can be your computer or a remote storage space.

## State stored locally

"local" backend is used to store the state file locally.

```bash
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}
```

## State stored remotelly

### Terraform solution

https://terragrunt.gruntwork.io/docs/features/state-backend/#motivation

```bash
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "frontend-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}
```

One important issue with this solution:

- The resources used for remote state are going to be provisioned somewhere else, **and that somewhere else needs to be managed.**

- Most users end up using `"click-ops"` to provision the **S3 bucket and DynamoDB table used for AWS remote state** (clicking around in the AWS console until they have what they need).

- This is error-prone, difficult to reproduce, and makes it hard to do the right thing consistently (e.g., enabling versioning, encryption, and access logging).

### Terragrunt solution

https://terragrunt.gruntwork.io/docs/features/state-backend/#generating-remote-state-settings-with-terragrunt

#### `generate` block

```bash
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-lock-table"
  }
}
EOF
}
```

- The generate block is useful for allowing you to setup the remote state backend configuration automatically, **but this introduces a bootstrapping problem: how do you create and manage the underlying storage resources for the remote state?**

- When using the s3 backend, **Terraform expects the S3 bucket to already exist for it to upload the state objects.**

#### `remote_state` block

- The `remote_state` block provides an alternative to using the generate block.

- Terragrunt uses the settings provided in the `remote_state` block **to configure the backend without requiring a pre-existing backend block in your Terraform code.**

- This setup is ideal for centralizing remote state configuration and **automatically creating necessary resources (S3 bucket, DynamoDB table, IAM roles/policies)** if they do not already exist.

- You can not use both methods at the same time to manage the remote state configuration. When implementing `remote_state`, be sure to remove the `generate` block for managing the backend.

```bash
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "gitos-manifests-repo"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "gitops-manifests-repo-lock"
  }
}
```

- Key Points:

1. **Bucket:** The state is stored in the S3 bucket named `gitops-manifests-repo`.

1. **Key:** The state file path is **dynamically generated** using `${path_relative_to_include()}` so that each module's state is stored separately.

1. **Region & Encryption:** The state file is stored in the `us-east-1` region and is `encrypted.`

1. **Locking:** The DynamoDB table (`gitops-manifests-repo-lock`) is used to lock the state during operations, **preventing concurrent changes.**

## Backups

Once stored in S3, we can apply all sorts of backup policies.

## Validating Remote State files

We can use AWS CLI commands to check for files generated when provisioning infrastructure:

```bash
infrastructure/environments/prod
❯ aws s3 ls
2025-03-08 10:11:09 gitos-manifests-repo
```

```bash
infrastructure/environments/prod
❯ aws s3 ls s3://gitos-manifests-repo --recursive

2025-03-08 10:28:59      21465 environments/prod/clusters/eks-cluster-a/addons/load-balancer-controller/terraform.tfstate
2025-03-08 10:29:06      16986 environments/prod/clusters/eks-cluster-a/addons/metrics-server/terraform.tfstate
2025-03-08 10:27:45     125589 environments/prod/clusters/eks-cluster-a/cluster/terraform.tfstate
2025-03-08 10:29:35     159240 environments/prod/clusters/eks-cluster-a/karpenter/terraform.tfstate
2025-03-08 10:13:39      39316 environments/prod/networking/terraform.tfstate
```

## References

https://terragrunt.gruntwork.io/docs/features/state-backend/#create-remote-state-resources-automatically
