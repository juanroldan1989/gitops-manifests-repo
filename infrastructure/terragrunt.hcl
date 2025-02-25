# TODO: provide alternative configuration with S3 as remote state backend
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

locals {
  # locals available to all environments
  backend_config = read_terragrunt_config(find_in_parent_folders("backend.hcl"))
  aws_account_id = local.backend_config.locals.aws_account_id
  aws_region     = local.backend_config.locals.aws_region

  # locals specific to a environment
  env_vars             = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env                  = local.env_vars.locals.env
  aws_provider_version = local.env_vars.locals.aws_provider_version
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "${local.env}"
      CostCenter  = "AWS Billing"
      ManagedBy   = "Terraform"
      Owner       = "Platform Team"
    }
  }
}
EOF
}

generate "terraform" {
  path      = "required_providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> ${local.aws_provider_version}"
    }

    argocd = {
      source = "claranet/argocd"
      version = "5.6.0-claranet0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
  }
}
EOF
}
