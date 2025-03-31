# gitops-manifests-repo

![how-does-gitops-work](https://github.com/user-attachments/assets/46b60c9a-3c8b-4ecc-a853-a13debff154b)

1. [Workflow Overview](#workflow_overview)
1. [How It Works](#how_it_works)
1. [Setup](#setup)
1. [Key Benefits](#key_benefits)
1. [Disaster Recovery](#disaster_recovery)
1. [Contributing](#contributing)
1. [License](#license)

<hr>

- This repository contains `Kubernetes` manifests for our `GitOps` workflow.
- Changes to these manifests are managed declaratively via `Git` and deployed automatically using `ArgoCD`.
- Supporting infra is provisioned through `Terraform`, `Terragrunt` and `AWS`.

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

- [`local` setup guide](/infrastructure/environments/local/README.md)
- [`production` setup guide](/infrastructure/environments/prod/README.md)

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

## Work in progress (TODO)

- Ephemeral environments setup within Pull Request.

- **Monitor and Observe**:

-- Set up comprehensive monitoring (e.g., `Prometheus`, `Grafana`, `ELK/EFK` stack) and logging to keep track of inter-service communications, performance, and failures. Setup in a way it can be re-used to any other applications.

-- [Charts reference](https://www.youtube.com/watch?v=cL0biQxREFI&list=WL&index=1&t=521s).

-- Generate built-in dashboards: `Example App - HPA Replicas`, `Example App - CPU Usage - Avg per Cluster`, `Example App - Memory Usage - Avg per Cluster`, `Example App - CPU Throttling`, and more.

-- Generate "templates" with different sets of dashboards.

- **Add several applications** that rely in N microservices. E.g.: uber-eats

- **Implemement ArgoCD Application Set**: 1 AppSet -> N Applications. To organise better the UI space and clarity on resources.

- **Adopt a Service Mesh**: For internal communications and to provide observability, security, and resilience among 50+ services, a service mesh can be invaluable.

- **Monitor Kubernetes Cloud** Costs: https://www.kubecost.com/install#show-instructions

## Contributing

Contributions are welcome and greatly appreciated! If you would like to contribute to this project, please follow the guidelines within [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the terms of the [MIT License](LICENSE).
