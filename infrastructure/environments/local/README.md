# Local Cluster Setup with kind

If you want to quickly test your apps on a local Kubernetes cluster, you can use kind (Kubernetes IN Docker). Follow these steps:

## Prerequisites

- `Docker`: Make sure Docker is installed and running on your machine.
- `kubectl`: Install kubectl to interact with your cluster.
- `kind`: Install kind using one of the methods below:

## Installing kind

```bash
brew install kind
```

## Provision infrastructure

### Create a Cluster Configuration File (Optional)

You can create a configuration file to customize your cluster. For example, create a file named kind-config.yaml:

```bash
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
```

This config maps common HTTP/HTTPS ports from your local machine to the cluster.

### Create the Local Cluster

If you’re using a configuration file:

```bash
kind create cluster --name local-eks --config kind-config.yaml
```

```bash
Creating cluster "local-eks" ...
 ✓ Ensuring node image (kindest/node:v1.32.2) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-local-eks"
You can now use your cluster with:

kubectl cluster-info --context kind-local-eks

Not sure what to do next? 😅  Check out https://kind.sigs.k8s.io/docs/user/quick-start/
```

Or, to create a default cluster:

```bash
kind create cluster --name local-eks
```

### Verify the Cluster is Running

Check the cluster status with:

```bash
kubectl cluster-info --context kind-local-eks
```

This command should display information about your local Kubernetes API server.

### Deploy ArgoCD & ArgoCD Applications

Same instructions as within [argocd](/argocd/README.md) folder

### Deploy Applications

With your local cluster up and running, you can now deploy your Kubernetes manifests (or `ArgoCD` if you wish to test the GitOps workflow locally). For example:

```bash
kubectl apply -R -f manifests
```

Follow the same process as in your production workflow, adjusting as necessary for a local environment.

## Remove infrastructure

1. Remove ArgoCD Applications
2. K8S Application resources (Deployment, Ingress, Service, HPA) are removed automatically.
3. Remove ArgoCD itself.
4. Delete `kind` cluster
