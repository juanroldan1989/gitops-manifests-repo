# External Secret Operator (ESO)

https://external-secrets.io/latest/introduction/getting-started/

## Setup

1. Create `external-secrets` Namespace:

```bash
kubectl create ns external-secrets
```

2. Store `AWS Credentials` within Secret in `external-secrets` namespace:

```bash
kubectl create secret generic awssm-secret \
  -n external-secrets \
  --from-literal=access-key=<access-key> \
  --from-literal=secret-access-key=<secret-access-key>
```

3. Install External Secrets Operator (ESO):

- Via ArgoCD:

```bash
kubectl apply -f argo/apps/eso.yaml
```

- Via Helm:

```bash
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace
```

4. Ensure External Secrets controller has permission to read secrets in `external-secrets` namespace:

- If you're using RBAC (most setups do), the controller might not have permission to read secrets from the `external-secrets` namespace.

- You can fix this by creating a `ClusterRole` and `ClusterRoleBinding`:

- Via ArgoCD:

```bash
kubectl apply -f argo/apps/eso-config.yaml
```

- Or manually:

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-secrets-read-credentials
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-secrets-read-credentials
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-secrets-read-credentials
subjects:
  - kind: ServiceAccount
    name: external-secrets
    namespace: external-secrets
```


5. Create a `Cluster Secret Store` to **centralize AWS Provider connection**:

- Via ArgoCD (already included in step 4)

```bash
kubectl apply -f argo/apps/eso-config.yaml
```

- Or manually:

```bash
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: cluster-secretstore-sample
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        secretRef:                       # secretRef is used to authenticate with AWS Secrets Manager
          accessKeyIDSecretRef:          # accessKeyIDSecretRef/secretAccessKeySecretRef are used to authenticate with AWS
            name: awssm-secret
            key: access-key
            namespace: external-secrets  # Namespace where the `awssm-secret` secret is located
          secretAccessKeySecretRef:
            name: awssm-secret
            key: secret-access-key
            namespace: external-secrets
```

6. Create `External Secret` resource:

- This resource will **fetch secrets from AWS**
- And **create Kubernetes Secret** resources needed by our applications
- This step is already generated for every `Deployment` resource provisioned, based on the custom `values.yaml` provided for each application:

```bash
...
env:
  - name: DATABASE_URL
    secret: true
    secretName: greeter-saver-secret
    secretKey: database-url
```

- An `ExternalSecret` resource can also be created manully if needed:

```bash
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sample-external-secret
  namespace: sample-ns
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: cluster-secretstore-sample
    kind: ClusterSecretStore
  target:
    name: sample-app-secret             # Name of the resulting Kubernetes Secret
    creationPolicy: Owner
  data:
    - secretKey: database-url           # The key name in the resulting Kubernetes Secret
      remoteRef:
        key: sample-secret-in-aws       # Name of the secret in AWS Secrets Manager
        property: key-for-secret-value  # The specific key within the secret in AWS Secrets Manager
```
