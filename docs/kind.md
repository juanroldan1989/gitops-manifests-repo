# Kind Cluster Setup Guide

This guide provides everything you need to run a local Kubernetes cluster with [Kind](https://kind.sigs.k8s.io/) that simulates production environments.

## What Is Kind?

Kind (Kubernetes IN Docker) is a tool for running local Kubernetes clusters using Docker container nodes. It's perfect for testing GitOps workflows locally.


## Requirements

- Docker installed and running
- `kind` CLI installed ([Install Guide](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- `kubectl` installed and configured

## Cluster Configuration

Your Kind cluster config is defined in `bootstrap/kind-cluster.yaml` and includes:

- 1 control-plane node
- 2 worker nodes
- Taints added to a worker node to simulate production node constraints

### Taint Details

```yaml
register-with-taints: "CriticalAddonsOnly=true:NoSchedule"
```

This matches the taints applied to production nodes in EKS, so components like ArgoCD and ESO will only schedule with appropriate tolerations.


## Create the Cluster

```bash
kind create cluster --name gitops-dev --config bootstrap/kind/cluster.yaml
```

To delete it later:

```bash
kind delete cluster --name gitops-dev
```


## Validate the Cluster

Ensure nodes are ready:

```bash
kubectl get nodes
```

Check that the taint is applied:

```bash
kubectl describe node | grep -A5 Taints
```

## Tips for Development

- Use `kubectl config use-context kind-gitops-dev` if needed
- You can use `kubectl port-forward` or add an Ingress controller for local URLs
- `bootstrap/bootstrap.sh` will install ArgoCD, ESO, and your applications


## Next Step

Once the cluster is up:

```bash
./bootstrap/bootstrap.sh --cluster-name gitops-dev
```

This will install everything and replicate your production setup.

**To install specific apps:**

```bash
./bootstrap/bootstrap.sh --cluster-name gitops-dev --apps greeting-app name-app
```

## 🧼 Cleanup

To remove all local state:

```bash
kind delete cluster --name gitops-dev
```
