include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/networking"
}

inputs = {
  # environment
  aws_account_id = include.root.locals.aws_account_id
  aws_region     = include.root.locals.aws_region
  env            = include.root.locals.env

  # custom
  eks_name = "eks-a"
}
