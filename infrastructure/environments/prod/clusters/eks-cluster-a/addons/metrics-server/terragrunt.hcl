include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "git::https://github.com/juanroldan1989/infra-modules.git//modules/eks/addons/metrics-server"
}

dependency "cluster" {
  config_path = find_in_parent_folders("cluster")
  mock_outputs = {
    eks_name = "eks-cluster-a",
    eks_node_group_general = {
      node_group_name = "general",
      node_group_id   = "ng-1234567890abcdef0"
    }
  }
}

inputs = {
  eks_name               = dependency.cluster.outputs.eks_name
  eks_node_group_general = dependency.cluster.outputs.eks_node_group_general
}
