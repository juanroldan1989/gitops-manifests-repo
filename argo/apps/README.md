# Applications

## ArgoCD Dashboard

<img width="1718" alt="Screenshot 2025-03-29 at 18 45 50" src="https://github.com/user-attachments/assets/9d4bbc64-96d2-4ac0-b708-6845811766c0" />

## Manual Provisioning

1. [ArgoCD](/argo/ARGOCD.md)
2. [ArgoRollouts](/argo/ARGOROLLOUTS.md)
3. [External Secrets Operator](/argo/ESO.md)
4. Provision Apps as needed with:

```bash
kubectl apply -f argo/apps/<app-name>.yaml
```

## Fully Automated Provisioning

This script automates the full provisioning of a local `Kubernetes` cluster using `kind`, installing **essential GitOps** components and `applications` in a **repeatable and consistent way.**

1. **Creates a `kind` Kubernetes cluster** named `gitops-dev` with:
   - 1 control-plane node with port mappings for HTTP/HTTPS
   - 2 worker nodes

2. **Reads AWS credentials** from your local `~/.aws/credentials` file (default profile) and creates a Kubernetes `Secret` (`awssm-secret`) in the `external-secrets` namespace.

3. **Creates required namespaces** for tools:
   - `argocd`
   - `argo-rollouts`
   - `external-secrets`

4. **Installs core GitOps components**:
   - [ArgoCD](https://argo-cd.readthedocs.io/): `GitOps` controller for Kubernetes
   - [Argo Rollouts](https://argoproj.github.io/argo-rollouts/): `Progressive` delivery controller
   - [External Secrets Operator (ESO)](https://external-secrets.io/): Sync secrets from **AWS Secrets Manager or SSM** into `Kubernetes` cluster.

5. **Deploys your ArgoCD applications** from YAML manifests located in the `argo/apps/` folder.
   - Supports deploying **all apps** or a **specific list**.

## Repo Structure required

```bash
root/
├── bootstrap.sh                  # <-- This script
└── argo/
    └── apps/
        ├── eso.yaml
        ├── eso-config.yaml
        ├── greeter-app.yaml
        ├── greeting-app.yaml
        └── name-app.yaml
        ...
```

## Usage

### Install all apps:

```bash
./bootstrap.sh
```

### Install specific apps only:

```bash
./bootstrap.sh --apps greeter-app name-app
```

> This is similar to: `docker-compose up greeter-app name-app`

## AWS Secret Handling

- The script extracts AWS credentials from the `default` profile in `~/.aws/credentials`.
- It creates a `Secret` called `awssm-secret` in `external-secrets` namespace.
- This is used by ESO to fetch secrets from AWS.

## Requirements

- [Docker](https://www.docker.com/) + [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [AWS CLI](https://aws.amazon.com/cli/) configured locally
- Internet access to pull manifests
