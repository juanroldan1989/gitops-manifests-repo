# ArgoCD Installation on EKS Cluster

## Step 1: Create the ArgoCD Namespace

```bash
kubectl apply -f namespace.yaml
```

## Step 2: Deploy ArgoCD

### Default installation

- ArgoCD provides an official installation manifest that deploys all the necessary components like the API server, controller, repository server, and UI.

- To deploy ArgoCD, use the following command:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

- Removing ArgoCD resources

```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

### Custom installation (only in specific default managed node groups)

1. To ensure that ArgoCD’s pods are scheduled on our `EKS` managed node groups (and not on nodes provisioned by Karpenter):

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd --namespace argocd --create-namespace -f values.yaml
```

2. Enable ingress in the values file `server.ingress.enabled` and either:

- Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough

- Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts

3. Removing `ArgoCD` resources:

```bash
helm uninstall argocd --namespace argocd
kubectl delete namespace argocd
```

## Step 3: Expose ArgoCD using an Ingress

- Ingress configuration to expose the ArgoCD UI externally

```bash
kubectl apply -f ingress.yaml
```

- Enforce HTTPS connections within external ALB -> [steps](/argocd/INGRESS.md)

## Step 4: Access the ArgoCD UI

1. Get the ArgoCD Admin Password:

```bash
kubectl get pods -n argocd
kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

2. Port-Forward to Access ArgoCD UI Locally:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

3. Access the UI at `https://localhost:8080`

4. Login using the username: `admin` and the decoded password.

## Step 5: Connect the `gitops-manifests-repo` to ArgoCD

1. Create a manifest file for the ArgoCD Application: `app-a.yaml`

2. Apply the ArgoCD application:

```bash
kubectl apply -f app-a.yaml
```

3. Verify that the Application is Synced:

```bash
kubectl get applications -n argocd
```

4. Check the ArgoCD UI to ensure that application "A" has been deployed and is in sync.

## Step 6: Automating Updates via GitOps

Automating Changes from the Source Repository:

1. Changes are pushed to the `gitops-source-repo`.

2. Once its `CI/CD` pipeline completes succesfully, it creates a Pull Request updating manifests in the `gitops-manifests-repo`.

3. Within `gitops-manifests-repo`, once the new Pull Request is merged, `ArgoCD` automatically **detects these changes and syncs them** to our `EKS` cluster.

4. Ensuring the **EKS cluster state always matches the state defined** in our `gitops-manifests-repo`.

## Step 7: Removing everything

```bash
# ArgoCD Apps
kubectl delete -R -f argocd
```

```bash
# EKS Apps
kubectl delete -R -f manifests
```

```bash
# Infrastructure
cd infrastructure/environments/prod

./infra-management.sh destroy
```
