# Applications

## ArgoCD Dashboard

<img width="1718" alt="Screenshot 2025-03-29 at 18 45 50" src="https://github.com/user-attachments/assets/9d4bbc64-96d2-4ac0-b708-6845811766c0" />

## Provisioning

1. [ArgoCD](/argo/ARGOCD.md)
2. [ArgoRollouts](/argo/ARGOROLLOUTS.md)
3. [External Secrets Operator](/argo/ESO.md)
4. Provision Apps as needed with:

```bash
kubectl apply -f argo/apps/<app-name>.yaml
```

## 1 Script to provision everything (TODO)

- Generate a single script to:

1. Read my AWS credentials stored in `~/.aws/credentials`.
2. Use them to create a generic `aws-ssm` Kubernetes Secret.
3. Provision all the tools (ArgoCD, ArgoRollouts, ESO) my cluster will need.
4. Provision all the apps I want in my cluster via different methods:

- Providing a list of **applications names** -> similar to `docker-compose up <app_name_1> <app_name_2>`.
- **Without a list** of applications names -> this means to install all apps within `argo/apps` folder.
