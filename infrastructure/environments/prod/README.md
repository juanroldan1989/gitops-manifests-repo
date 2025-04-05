# `production` environment

## ArgoCD Dashboard

<img width="1718" alt="Screenshot 2025-03-29 at 18 45 50" src="https://github.com/user-attachments/assets/9d4bbc64-96d2-4ac0-b708-6845811766c0" />

### 1. Provision Infrastructure

```bash
cd infrastructure/environments/prod
./infra-management.sh apply
```

This script provisions components such as:

- **Networking**: Configured using `Terragrunt` scripts for scalable and secure network setup.
- **Amazon EKS Cluster**: Provisioned using `Terragrunt` scripts to ensure a consistent and auditable deployment.
- **Karpenter**: Provides auto-scaling capabilities to EKS Cluster nodes based on metrics like CPU/Memory usage.

This script uses:

- **Modules:** Infrastructure modules are sourced from the [infra-modules](https://github.com/juanroldan1989/infra-modules/) repository.
- **Tools:** `Terraform` and `Terragrunt`.
- **Cloud Provider:** `AWS`.

### 2. Infrastructure State Management

For details instructions in 2 ways of handling infrastructure's **state**, please check [this guide](/docs/infra-state-management/README.md)

### 3. Provision addons and Deploy Apps in EKS Cluster

All steps automated within `/bootstrap-prod.sh --apps name-app greeting-app greeter-saver-app`.

### 4. Source Code repo: Application Development & Deployment

- Developers update source code in [gitops-source-repo](https://github.com/juanroldan1989/gitops-source-repo) and create a pull request (e.g., `"Changes to app-a: Landing page"`).

- After merging, the pipeline will generate a pull request in [gitops-manifests-repo](https://github.com/juanroldan1989/gitops-manifests-repo) for updating the manifest with the new `image` version.

- Once merged, `ArgoCD` will **sync the new image to the EKS cluster** and automatically deploy the apps (e.g., `greeter-app`, `greeting-app`, `name-app`) from the `manifests` folder.

### 5. Manage deployments in `manifests` repo: ArgoCD / ArgoRollouts

Follow the steps in the [ArgoRollouts setup guide](/docs/argo/ARGOROLLOUTS.md)
