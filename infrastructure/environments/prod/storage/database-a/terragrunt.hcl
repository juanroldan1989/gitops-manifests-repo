include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/database"
}

dependency "networking" {
  config_path = find_in_parent_folders("networking")
  mock_outputs = {
    vpc_id = "vpc-1234567890abcdef0"
  }
}

inputs = {
  # environment
  aws_account_id = include.root.locals.aws_account_id
  aws_region     = include.root.locals.aws_region
  env            = include.root.locals.env

  # custom
  vpc_id                   = dependency.networking.outputs.vpc_id
  engine                   = "postgres"
  engine_version           = "11.5"
  instance_class           = "db.t3.micro"
  db_username              = "admin"
  db_password              = "password"
  parameter_group_name     = "default.postgres11"
  db_port                  = 5432
  private_subnets          = dependency.networking.outputs.subnet_ids
  origin_sg_id             = "sg-1234567890abcdef0"
}
