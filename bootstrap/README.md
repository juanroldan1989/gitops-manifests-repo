# Bootstrap Script

This directory contains the tools needed to install `GitOps` tooling and deploy applications into any Kubernetes cluster,

**whether it's a local Kind cluster or an AWS EKS cluster.**

## Script Overview: `bootstrap.sh`

This script automates the provisioning of `GitOps` tooling and `application` deployment. It:

1. Ensures access to a running Kubernetes cluster (via `kubectl`)
2. Creates required namespaces (`argocd`, `argo-rollouts`, `external-secrets`)
3. Reads AWS credentials from the default profile and creates a secret for ESO
4. Installs **ArgoCD** using Helm and a unified `values.yaml`
5. Installs **External Secrets Operator (ESO)**
6. Deploys ArgoCD **Applications** to manage workloads defined in `argo/apps/`

## Resources Provisioned

### ArgoCD

- `GitOps` engine that **continuously syncs manifests from Git**
- Installed using the official Helm chart
- Configured with tolerations (e.g., `CriticalAddonsOnly`) to work on tainted nodes

### External Secrets Operator (ESO)

- Allows Kubernetes to sync secrets from AWS SSM or Secrets Manager
- Config and manifests stored in `argo/apps/eso.yaml` and `eso-config.yaml`

### ArgoCD Applications

- Declarative app resources defined in `argo/apps/`
- Each YAML file points to a Helm-based application under `manifests/`

## Usage

### Prerequisites

- Your `kubeconfig` should point to a **valid, reachable cluster** (e.g., `kind-gitops-dev` or an EKS cluster)
- AWS credentials must be available locally via the `default` profile in `~/.aws/credentials`

### Install all apps into a cluster:

```bash
./bootstrap.sh --cluster-name gitops-dev
```

### Install only specific apps:

```bash
./bootstrap.sh --cluster-name prod-eks-cluster-a --apps greeting-app name-app
```

> 🔐 Secrets will be synced automatically by ESO once the AWS credentials are available

## Related Files

### `bootstrap/argo/values.yaml`

- Helm values used to configure ArgoCD across all environments
- Includes tolerations to match production taints

### `bootstrap/kind/cluster.yaml`

- Defines the Kind cluster with tainted nodes to match production behavior
- Used to replicate production taints for local testing

## Notes for DevOps Engineers

- The script is **idempotent** and safe to run multiple times
- `ArgoCD` installation is skipped if already present
- `Namespaces` and `secrets` are only created if missing
- You can pair this with the `Setup` section in [README](/README.md) to create full environments quickly.
