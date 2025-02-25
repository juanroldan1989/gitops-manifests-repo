include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/eks/addons/load-balancer-controller"
}

dependency "networking" {
  config_path = find_in_parent_folders("networking")
  mock_outputs = {
    vpc_id = "vpc-1234567890abcdef0"
  }
}

dependency "cluster" {
  config_path = find_in_parent_folders("cluster")
  mock_outputs = {
    eks_name = "eks-cluster-a"
  }
}

inputs = {
  # environment
  aws_account_id = include.root.locals.aws_account_id
  aws_region     = include.root.locals.aws_region
  env            = include.root.locals.env

  # custom
  vpc_id   = dependency.networking.outputs.vpc_id
  eks_name = dependency.cluster.outputs.eks_name
}
