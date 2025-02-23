include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules//eks/cluster"
}

dependency "networking" {
  config_path = find_in_parent_folders("networking")
}

inputs = {
  # environment
  aws_account_id = include.root.locals.aws_account_id
  aws_region     = include.root.locals.aws_region
  env            = include.root.locals.env

  # custom
  eks_name        = "eks-a"
  private_subnets = dependency.networking.outputs.subnet_ids
  eks_version     = "1.30"
}
