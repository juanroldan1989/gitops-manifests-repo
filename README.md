# gitops-manifests-repo

![how-does-gitops-work](https://github.com/user-attachments/assets/46b60c9a-3c8b-4ecc-a853-a13debff154b)

## Overview

This repository contains `Kubernetes` application manifests used in our GitOps workflow.

Changes to these `manifests` are managed **declaratively through GIT** and automated using ArgoCD, Terraform and Terragrunt.

## Setup

1. Provision infrastructure components:

```bash
cd infrastructure/environments/prod

./infra-management.sh apply
```

2. Install ArgoCD in EKS cluster with [these steps](/argocd/README.md)

3. `app-a` from `manifests` folder is automatically provisioned by ArgoCD afterwards.

4. Adjust `app-a` application source code within [gitops-source-repo](https://github.com/juanroldan1989/gitops-source-repo). Create Github Pull Request `Changes to app-a: Landing page`, review, approve and merge it.

5. Once Pull Request is merged, pipeline creates a new Pull Request `app-a: new image version` within the manifests repository: [gitops-manifests-repo](https://github.com/juanroldan1989/gitops-manifests-repo)

6. Once this Pull Request `app-a: new image version` is merged, `ArgoCD` syncs up the new `app-a` image version within the EKS cluster.

## Workflow

### Source of Truth

The repository is **automatically updated** via pull requests triggered **on-demand** by the [gitops-source-repo](https://github.com/juanroldan1989/gitops-source-repo) once a GitHub Actions workflow completes **successfully**

### Manifest Updates

For example, the **image** field in `/manifests/app-a/deployment.yaml` is updated as part of this automated process.

### Continuous Delivery

Once a pull request is merged, `ArgoCD` detects changes in the `manifests/app-*` folders and synchronizes the respective application resources in the Kubernetes cluster.

## Infrastructure

This repository is part of our **infrastructure-as-code** setup and provisions the following components:

- Networking
- Amazon EKS Cluster
- Karpenter
- ArgoCD

### Implementation

- Modules: Infrastructure modules are sourced from the [infra-modules](https://github.com/juanroldan1989/infra-modules/) repository.

- Tools: The infrastructure is provisioned using `Terraform`, `Terragrunt` and AWS.

### Networking

Provisioned using Terragrunt scripts to ensure scalable and secure networking.

### Clusters

EKS clusters are provisioned using Terragrunt scripts, providing a consistent, repeatable, and auditable deployment process.

## ArgoCD

- Provisioned via `Helm` chart.

- `ArgoCD` is a **declarative, GitOps-based continuous delivery** tool for Kubernetes.

- It allows to manage Kubernetes applications by

1. **storing the desired state of the cluster in a Git repository** and

2. **automating the process of syncing that state** to the actual cluster.

- In a GitOps workflow, ArgoCD acts as **the bridge between applications code and the Kubernetes infrastructure**, ensuring that the changes in your Git repository are always reflected in the cluster.

### Workflow Overview

We've got 2 repositories:

- `gitops-source-repo`: This repository contains your application source code, pipelines, and other CI/CD configurations.
- `gitops-manifests-repo`: This repository holds the Kubernetes manifests for deploying your applications, such as Deployments, Services, and Ingress resources.

### The GitOps workflow facilitated by ArgoCD operates as follows

<br>

![gitops-workflow](https://github.com/user-attachments/assets/e944156e-2ab3-41db-a9cb-4892aa849307)

### 1. Code Changes in Source Repo

When developers push changes to the `gitops-source-repo` (such as modifying application code or configuration files), the changes trigger a CI/CD pipeline (e.g.: GitHub Actions, or another tool).

### 2. Pipeline Updates the Manifests Repo

The CI/CD pipeline builds the new application version, generates a new container image, pushes the new image into `ECR` and updates the relevant Kubernetes manifests in the `gitops-manifests-repo` with the `new image tag` or other necessary configuration changes.

### 3. ArgoCD Watches for Changes

- ArgoCD is configured to watch the `gitops-manifests-repo`.

- **When changes are detected in this repository**, ArgoCD automatically **synchronizes** the Kubernetes manifests with your Amazon EKS (Elastic Kubernetes Service) cluster.

### 4. Cluster State Reconciliation

- ArgoCD ensures that the **EKS cluster's state matches the desired state defined** in the `gitops-manifests-repo`.

- If there are discrepancies, ArgoCD will automatically apply the necessary changes to bring the cluster **back to the desired state.**

### Key Benefits

Using ArgoCD to implement GitOps offers several benefits:

1. **Declarative Infrastructure:** All your infrastructure and application states are stored as code in the `gitops-manifests-repo`, providing a single source of truth.

2. **Continuous Deployment Automation:** Changes in the manifests are automatically reflected in your EKS cluster without manual intervention, reducing human errors.

3. **Rollback and Auditing:** Since all changes to your Kubernetes manifests are version-controlled in Git, you can easily roll back to a previous state if something goes wrong. Additionally, the Git history provides an audit trail of all changes made.

4. **Improved Developer Experience:** Developers focus on writing code and updating manifests, while ArgoCD handles the deployment process, simplifying the overall experience.

## Contributing

Contributions are welcome and greatly appreciated! If you would like to contribute to this project, please follow the guidelines within [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the terms of the [MIT License](LICENSE).
