# gitops-manifests-repo

- This repository only contains Kubernetes `applications` manifests.
- A specific manifest (e.g.: `/manifests/app-a/deployment.yaml` -> `image` field) is updated based on its counterpart `Github Actions` pipeline being completed within the `gitops-source-repo`.

## Provision Infrastructure

Terraform + Terragrunt + AWS

### Networking

Provisioned via Terragrunt script.

### Clusters

Provisioned via Terragrunt script.

## ArgoCD

ArgoCD is a declarative, GitOps-based continuous delivery tool for Kubernetes.

It allows to manage Kubernetes applications by storing the desired state of the cluster in a Git repository and automating the process of syncing that state to the actual cluster.

In a GitOps workflow, ArgoCD acts as **the bridge between applications code and the Kubernetes infrastructure**, ensuring that the changes in your Git repository are always reflected in the cluster.

### Workflow Overview

We've got 2 repositories:

- `gitops-source-repo`: This repository contains your application source code, pipelines, and other CI/CD configurations.
- `gitops-manifests-repo`: This repository holds the Kubernetes manifests for deploying your applications, such as Deployments, Services, and Ingress resources.

### The GitOps workflow facilitated by ArgoCD operates as follows

- Code Changes in Source Repo: When developers push changes to the `gitops-source-repo` (such as modifying application code or configuration files), the changes trigger a CI/CD pipeline (e.g.,GitHub Actions, or another tool).

- Pipeline Updates the Manifests Repo: The CI/CD pipeline builds the new application version, generates a new container image, and updates the relevant Kubernetes manifests in the `gitops-manifests-repo` with the new image tag or other necessary configuration changes.

- ArgoCD Watches for Changes: ArgoCD is configured to watch the `gitops-manifests-repo`. When changes are detected in this repository, ArgoCD automatically synchronizes the Kubernetes manifests with your Amazon EKS (Elastic Kubernetes Service) cluster.

- Cluster State Reconciliation: ArgoCD ensures that the EKS cluster’s state matches the desired state defined in the `gitops-manifests-repo`. If there are discrepancies, ArgoCD will automatically apply the necessary changes to bring the cluster to the desired state.

### Key Benefits

Using ArgoCD to implement GitOps offers several benefits:

- Declarative Infrastructure: All your infrastructure and application states are stored as code in the `gitops-manifests-repo`, providing a single source of truth.

- Continuous Deployment Automation: Changes in the manifests are automatically reflected in your EKS cluster without manual intervention, reducing human errors.

- Rollback and Auditing: Since all changes to your Kubernetes manifests are version-controlled in Git, you can easily roll back to a previous state if something goes wrong. Additionally, the Git history provides an audit trail of all changes made.

- Improved Developer Experience: Developers focus on writing code and updating manifests, while ArgoCD handles the deployment process, simplifying the overall experience.
