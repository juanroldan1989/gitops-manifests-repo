# gitops-manifests-repo

![how-does-gitops-work](https://github.com/user-attachments/assets/46b60c9a-3c8b-4ecc-a853-a13debff154b)

1. [Workflow Overview](#workflow_overview)
1. [How It Works](#how_it_works)
1. [Setup](#setup)
1. [Key Benefits](#key_benefits)
1. [Disaster Recovery](#disaster_recovery)
1. [Contributing](#contributing)
1. [License](#license)

# Repository structure

```bash
├── bootstrap/                            # 🔧 Bootstrap tools for any environment
│   ├── bootstrap.sh                      # Unified script to install ArgoCD, ESO, and deploy apps
│   ├── values.yaml                       # ArgoCD Helm values (used in both local and EKS)
│   └── kind-cluster.yaml                 # Kind config with taints for local testing
│
├── infrastructure/                       # 🏗️ Infra managed by Terraform + Terragrunt
│   ├── environments/
│   │   ├── local/
│   │   ├── prod/
│   │   ├── qa/
│   │   └── sandbox/
│   └── terragrunt.hcl
│
├── argo/                                 # 🧠 ArgoCD applications + ESO setup
│   ├── apps/
│   │   ├── eso.yaml
│   │   ├── eso-config.yaml
│   │   ├── greeter-app.yaml
│   │   ├── greeter-saver-app.yaml
│   │   ├── greeting-app.yaml
│   │   └── name-app.yaml
│   └── config/
│       └── values.yaml                   # (Optional) Helm values per ArgoCD app (if templating)
│
├── manifests/                            # 📦 Helm charts or templates per app
│   ├── base-application/                 # Shared Helm chart used by all apps
│   │   ├── Chart.yaml
│   │   └── templates/
│   │       └── ...
│   ├── greeter-app/
│   ├── greeter-saver-app/
│   ├── greeting-app/
│   └── name-app/
│       └── values.yaml
│
├── docs/                                 # 📘 Developer and DevOps documentation
│   ├── kind.md                           # Guide for local Kind cluster setup
│   └── argo/
│       ├── ARGOCD.md
│       ├── ARGOROLLOUTS.md
│       └── INGRESS.md
│
├── .github/                              # 🤖 Optional: for future GitHub Actions CI/CD
│   └── workflows/
│       └── (ephemeral-env-preview.yml)   # (Future idea: create preview envs per PR)
│
├── README.md
├── LICENSE
└── CONTRIBUTING.md
```

## Workflow Overview

Our GitOps workflow is built on **two core repositories:**

1. **gitops-source-repo**

- Contains the application source code, CI/CD pipelines, and configurations.
- Visit [gitops-source-repo](https://github.com/juanroldan1989/gitops-source-repo)

2. **gitops-manifests-repo**

- Contains the `Kubernetes` manifests (`Deployments`, `Services`, `Ingress`, etc.) for deploying applications.
- Visit [gitops-manifests-repo](https://github.com/juanroldan1989/gitops-manifests-repo)

## How It Works

1. **Code Changes in Source repo:**

- Developers commit changes to the [gitops-source-repo](https://github.com/juanroldan1989/gitops-source-repo), triggering a `CI/CD` pipeline (GitHub Actions).

2. **Pull request in source repo:**

- Pull request is created, building a new Docker image and pushing it to `ECR`.
- Pull request gets approved and merged.
- Pipeline creates a new Pull Request in [gitops-manifests-repo](https://github.com/juanroldan1989/gitops-manifests-repo)

3. **Manifest Updates in Manifests repo:**

- The new Pull Request created contains updates to the corresponding application manifests (e.g.: updating the **image tag** in `/manifests/greeter-app/values.yaml`):

```bash
...
app:
  name: greeter
  image: juanroldan1989/greeter:0.0.1
  port: 5000
...
```

- This Pull Request gets approved and merged in [gitops-manifests-repo](https://github.com/juanroldan1989/gitops-manifests-repo)

4. **ArgoCD Synchronization:**

- `ArgoCD` is configured to watch the manifests repository.
- `ArgoCD` detects these changes to the `/manifests/greeter-app/values.yaml`.
- `ArgoCD` synchronizes the `Kubernetes` cluster (`EKS`) **to match the desired state in GIT** by updating the Kubernetes Deployment.

<br>

![gitops-workflow](https://github.com/user-attachments/assets/e944156e-2ab3-41db-a9cb-4892aa849307)

## Setup

This guide helps new engineers to:

- spin up a **local or cloud environment**
- provision **infrastructure**
- install **GitOps** tools
- **deploy** applications

### Prerequisites

Ensure you have the following installed locally:

- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [kind](https://kind.sigs.k8s.io/)
- [aws CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Helm](https://helm.sh/docs/intro/install/)
- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- AWS credentials properly configured (e.g. via `~/.aws/credentials`)


### Option 1: Local Development Environment (Kind)

#### 1. Create the Kind cluster

```bash
kind create cluster --name gitops-dev --config bootstrap/kind/cluster.yaml
```

#### 2. Bootstrap the cluster with GitOps tools and applications

```bash
./bootstrap/bootstrap.sh --cluster-name gitops-dev
```

**To install specific apps:**

```bash
./bootstrap/bootstrap.sh --cluster-name gitops-dev --apps greeting-app name-app
```

### Option 2: Cloud Environment (AWS EKS)

#### 1. Provision infrastructure using Terragrunt

```bash
cd infrastructure/environments/prod
./infra-management.sh apply
```

#### 2. Update your local kubeconfig for the EKS cluster

```bash
aws eks update-kubeconfig --name prod-eks-cluster-a --region us-east-1
```

#### 3. Bootstrap the cluster with GitOps tools and applications

```bash
./bootstrap/bootstrap.sh --cluster-name prod-eks-cluster-a
```

**To install specific apps:**

```bash
./bootstrap/bootstrap.sh --cluster-name prod-eks-cluster-a --apps greeting-app name-app
```

### Useful Tips

- All `GitOps` apps are defined in `argo/apps/`
- Application manifests are parameterized in `manifests/`
- Core `ArgoCD` and `ESO` values are defined in `bootstrap/values.yaml`
- Local `Kind` nodes replicate production taints using `kind-cluster.yaml`

## Key Benefits

ArgoCD is a **declarative, GitOps-based continuous delivery tool for Kubernetes**.

It **bridges the gap between your application code and the Kubernetes cluster** by ensuring the cluster always reflects the desired state defined in Git.

Using ArgoCD to implement GitOps offers several benefits:

1. **Declarative Infrastructure:** All your infrastructure and application states are stored as code in the [gitops-manifests-repo](https://github.com/juanroldan1989/gitops-manifests-repo), providing a single source of truth.

2. **Continuous Deployment Automation:** Changes in the manifests are automatically reflected in your EKS cluster **without manual intervention, reducing human errors**.

3. **Rollback and Auditing:** Since all changes to your Kubernetes manifests are **version-controlled in Git**, you can easily roll back to a previous state if something goes wrong. Additionally, the Git history provides an audit trail of all changes made.

4. **Improved Developer Experience:** Developers focus on **writing code and pushing changes**, while ArgoCD updates manifests and handles the deployment process, simplifying the overall experience.

## Disaster Recovery

Steps to fully restore the entire platform (`Infrastructure` + `K8S Cluster` + `Applications`) -> [steps](/docs/recovery/README.md)

## Contributing

Contributions are welcome and greatly appreciated! If you would like to contribute to this project, please follow the guidelines within [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the terms of the [MIT License](LICENSE).
