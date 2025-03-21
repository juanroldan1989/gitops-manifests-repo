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
kubectl create ns argo-rollouts
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
kubectl apply -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/dashboard-install.yaml
```

- Removing Argo Rollouts resources:

```bash
kubectl delete -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/install.yaml
kubectl delete -n argo-rollouts -f https://raw.githubusercontent.com/argoproj/argo-rollouts/stable/manifests/dashboard-install.yaml

kubectl delete namespace argo-rollouts
```

### Custom installation (only in specific default managed node groups)

1. To ensure that `Argo Rollout`'s pods are scheduled on our `EKS` managed node groups (and not on nodes provisioned by Karpenter):

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argo-rollouts argo/argo-rollouts --namespace argo-rollouts --create-namespace -f values.yaml
```

2. Removing `Argo Rollout` resources:

```bash
helm uninstall argo-rollouts --namespace argo-rollouts
kubectl delete namespace argo-rollouts
```

## 3. Install Argo Rollouts plugin for kubectl

```bash
brew install argoproj/tap/kubectl-argo-rollouts
```

## 4. Enable rollout for a specific application

For example, `name-app` folder, adjusting `values.yaml` to enable rollouts:

```bash
...
rollout:
  enabled: true # Rollout resource is created and deployment is not
```

## 5. Watching rollouts

### Via CLI

```bash
kubectl argo rollouts get rollout name-rollout -n greeter-app -w
```

```ruby
Name:            name-rollout
Namespace:       greeter-app
Status:          ✔ Healthy
Strategy:        Canary
  Step:          8/8
  SetWeight:     100
  ActualWeight:  100
Images:          juanroldan1989/name:0.0.1 (stable)
Replicas:
  Desired:       10
  Current:       10
  Updated:       10
  Ready:         10
  Available:     10

NAME                                     KIND        STATUS     AGE    INFO
⟳ name-rollout                           Rollout     ✔ Healthy  15m
└──# revision:1
   └──⧉ name-rollout-d4f867f6d           ReplicaSet  ✔ Healthy  12m    stable
      ├──□ name-rollout-d4f867f6d-dkvkh  Pod         ✔ Running  12m    ready:1/1
      ├──□ name-rollout-d4f867f6d-64h7d  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-7z2vq  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-97xjt  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-b2j4m  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-bpk72  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-glccs  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-k6w69  Pod         ✔ Running  4m50s  ready:1/1
      ├──□ name-rollout-d4f867f6d-s5727  Pod         ✔ Running  4m50s  ready:1/1
      └──□ name-rollout-d4f867f6d-sghv4  Pod         ✔ Running  4m50s  ready:1/1
```

### Dashboard

```bash
kubectl argo rollouts dashboard
```

## Rollout a new image

1. Change Docker image version for `name` application within `manifests/name-app/values.yaml`

```bash
namespace: greeter-app
app:
  name: name
  image: juanroldan1989/name:latest # was 0.0.1 previously
  port: 5001
```

2. Create PR, review change and merge into `main` branch.

3. Follow rollout status within CLI:

![](/argocd/rollout.gif)

4. Since this rollout requires manual intervention on the first pause, we **promote** rollout (allow the deployment to continue) with:

```bash
kubectl argo rollouts promote name-rollout -n greeter-app
```

5. The rest of the pauses are automatic and each one continues with the deployment after `10 seconds`.

<div style="display: flex; justify-content: space-around; align-items: center;">
  <img src="https://github.com/user-attachments/assets/e6fb8b66-589e-432b-862a-5bd9c2f70cef" width="405" style="margin-right: 10px;" />
  <img src="https://github.com/user-attachments/assets/37ee0908-3ddf-4dff-aabb-6bab21edfffa" width="403" />
</div>

5. `Canary` deployment finishes when the new version is now the `stable` one.
