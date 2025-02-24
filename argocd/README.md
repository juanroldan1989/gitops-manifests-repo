# ArgoCD Installation on EKS Cluster

## Step 1: Create the ArgoCD Namespace

```bash
kubectl apply -f argocd-namespace.yaml
```

## Step 2: Deploy ArgoCD

- ArgoCD provides an official installation manifest that deploys all the necessary components like the API server, controller, repository server, and UI.

- To deploy ArgoCD, use the following command:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Step 3: Expose ArgoCD using an Ingress

- Ingress configuration to expose the ArgoCD UI externally

```bash
kubectl apply -f ingress.yaml
```

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

## Step 5: Connect the gitops-manifests-repo to ArgoCD

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

- When changes are pushed to the `gitops-source-repo`, its CI/CD pipeline updates the manifests in the `gitops-manifests-repo`.

- `ArgoCD` will automatically **detect these changes and sync them** to our EKS cluster, ensuring the **cluster state always matches the state defined** in the `gitops-manifests-repo`.