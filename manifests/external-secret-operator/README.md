# External Secret Operator

https://external-secrets.io/latest/introduction/getting-started/

## Setup

1. Install External Secrets via Helm:

```bash
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace
```

2. Ensure External Secrets controller has permission to read secrets in `external-secrets` namespace

- If you're using RBAC (most setups do), the controller might not have permission to read secrets from the external-secrets namespace.

- You can fix this by creating a ClusterRole and ClusterRoleBinding like this:

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

3. Store `AWS Credentials` within Secret in `external-secrets` namespace:

```bash
kubectl create secret generic awssm-secret \
  -n external-secrets \
  --from-literal=access-key=<your-access-key-id> \
  --from-literal=secret-access-key=<your-secret-access-key>
```

4. Create a Cluster Secret Store to centralize AWS Provider connection:

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

5. Create `External Secret` resource:

- This resource will take care of fetching secrets from AWS
- And creating the Kubernetes Secret needed by our applications

```bash
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: greeter-app-external-secret
  namespace: greeter-app
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: cluster-secretstore-sample
    kind: ClusterSecretStore
  target:
    name: greeter-saver-secret          # Name of the resulting Kubernetes Secret
    creationPolicy: Owner
  data:
    - secretKey: database-url           # The key name in the resulting Kubernetes Secret
      remoteRef:
        key: sample-secret-in-aws       # Name of the secret in AWS Secrets Manager
        property: key-for-secret-value  # The specific key within the secret in AWS Secrets Manager
```
