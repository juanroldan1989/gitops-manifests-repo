# ArgoCD Setup

## 1. Create the ArgoCD Namespace

```bash
kubectl apply -f namespace.yaml
kubectl create ns argocd
```

## 2. Deploy ArgoCD

### Default installation

- Ideal for `local` development in `local` environment: `/infrastructure/environments/local`.

- ArgoCD provides an official installation manifest that deploys all the necessary components like the API server, controller, repository server, and UI.

- To deploy ArgoCD, use the following command:

```bash
kubectl create ns argocd
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

## 3. Expose ArgoCD using an Ingress

- Ingress configuration to expose the ArgoCD UI externally

```bash
kubectl apply -f ingress.yaml
```

- Enforce HTTPS connections within external ALB -> [steps](/argocd/INGRESS.md)

## 4. Access the ArgoCD UI

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

## 5. Provision Applications inside K8S Cluster using ArgoCD

```bash
cd argocd

kubectl apply -R -f apps

application.argoproj.io/argocd-custom-app created
application.argoproj.io/argocd-greeter-app created
application.argoproj.io/argocd-greeting-app created
application.argoproj.io/argocd-name-app created
```

<img width="1482" alt="Screenshot 2025-03-08 at 11 57 51" src="https://github.com/user-attachments/assets/70b89e3f-5fc7-47b7-9b87-7b6575111841" />

<img width="1640" alt="Screenshot 2025-03-08 at 11 55 30" src="https://github.com/user-attachments/assets/97aa2377-8284-4235-a576-1947b350fe00" />

<img width="829" alt="Screenshot 2025-03-08 at 11 57 10" src="https://github.com/user-attachments/assets/e87aaa06-c6d8-4cef-a81c-a433dceba72f" />


## 6. Automating Updates via GitOps

Automating Changes from the Source Repository:

1. Changes are pushed to the `gitops-source-repo`.

2. Once its `CI/CD` pipeline completes succesfully, it creates a Pull Request updating manifests in the `gitops-manifests-repo`.

3. Within `gitops-manifests-repo`, once the new Pull Request is merged, `ArgoCD` automatically **detects these changes and syncs them** to our `EKS` cluster.

4. Ensuring the **EKS cluster state always matches the state defined** in our `gitops-manifests-repo`.

## 7. Removing resources

### ArgoCD Applications

- ArgoCD UI: Allows engineers to delete `ArgoCD Applications` and their `associated` K8S Applications resources (Deploy, Ingress, Service, HPA).

- `kubectl`: Using this command will only delete `ArgoCD` applications. It **will not** delete associated K8S Applications resources (`finalizers` have to be setup within YAML ArgoCD files).

```bash
kubectl delete -R -f argocd
```

### K8S application resources

- ArgoCD UI: when this option is used, underlying resources have already being deleted. E.g.: (ALBs)

- `kubectl`: Use this command to manually delete all underlying resources:

```bash
kubectl delete all -n custom-app
kubectl delete all -n greeter-app
```

### Infrastructure

```bash
cd infrastructure/environments/prod

./infra-management.sh destroy
```
