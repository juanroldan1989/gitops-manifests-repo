#!/bin/bash

## Usage:
### ./infra-management.sh apply
### ./infra-management.sh destroy

## This script provisions resources for:

## Environment: "prod"
## Cluster: "eks-cluster-a"

## Networking resources: VPC, subnets, route tables, internet gateway, security groups, NAT gateway

apply () {
  terragrunt run-all apply
}

destroy () {
dirs=(
  "./clusters/eks-cluster-a/addons"
  "./clusters/eks-cluster-a/cluster"
  "./networking"
)

for dir in "${dirs[@]}"; do
  echo "Destroying resources in $dir"
  cd "$dir" || exit 1
  terragrunt --terragrunt-non-interactive run-all destroy -auto-approve
  if [ $? -ne 0 ]; then
    echo "Error destroying resources in $dir"
    exit 1
  fi
  cd - || exit 1
done

echo "All resources destroyed successfully!"
}

if [ "$1" == "apply" ]; then
  apply
elif [ "$1" == "destroy" ]; then
  destroy
else
  echo "Usage: ./infra-management.sh apply"
  echo "Usage: ./infra-management.sh destroy"
fi
