# Argo Rollouts Setup

## 1. Create Namespace

```bash
kubectl create ns argo-rollouts
```

## 2. Deploy Argo Rollouts

### Default installation

- Ideal for `local` development in `local` environment: `/infrastructure/environments/local`.

- Argo Rollouts provides an official installation manifest that deploys all the necessary components like the API server, controller, repository server, and UI.

- To deploy Argo Rollouts, use the following command:

```bash
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
```

- Removing Argo Rollouts resources:

```bash
kubectl delete -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml

kubectl delete namespace argo-rollouts
```

## 3. Install Argo Rollouts plugin for kubectl

```bash
brew install argoproj/tap/kubectl-argo-rollouts
```

## 4. Setup Argo Rollout for a Deployment

For example, `greeter-app`.
