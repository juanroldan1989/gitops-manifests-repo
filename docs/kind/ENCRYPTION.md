# Encryption at Rest for Secrets

By default, Kubernetes stores `Secrets` as `base64-encoded` data in etcd.

Base64 **is not encryption**; it’s simply encoding.

For `true` security, you need to **enable encryption at rest** for your etcd cluster.

## 1. Create an Encryption Config File

Create [encryption-config.yaml](/infrastructure/environments/local/encryption-config.yaml)

### Notes

- The key must be a 32-byte (256-bit) value encoded in base64. For example, you can generate one using:

```bash
head -c 32 /dev/urandom | base64
```

- The `aescbc` provider encrypts `Secrets` and the identity provider acts as a fallback for already-encrypted data.

## 2. Create a Kind Configuration File

Kind allows you to pass extra arguments to the API server and mount files into the `control-plane` container.

- Create a `Kind` [config file](/infrastructure/environments/local/kind-config.yaml):

```bash
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraArgs:
      encryption-provider-config: "/etc/kubernetes/encryption-config.yaml"
    extraMounts:
      - hostPath: /Users/juanroldan/code/gitops-manifests-repo/infrastructure/environments/local/encryption-config.yaml
        containerPath: /etc/kubernetes/encryption-config.yaml
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

- Replace `/absolute/path/to/encryption-config.yaml` with the full path to your `encryption-config.yaml` file on your host machine.

## 3. Create Kind Cluster

Use your Kind configuration file to create the cluster:

```bash
kind create cluster --name local-eks --config kind-config.yaml
```

This command tells Kind to:

- Create a cluster named `local-eks` and use the extra arguments and mounts specified in your configuration file.
- The API server will then load your encryption configuration from `/etc/kubernetes/encryption-config.yaml`.

## 4. Verify the Setup

After your cluster is up, you can verify that encryption is enabled by:

- Inspecting etcd data (if you have direct access) to see that secret values are encrypted.
- Reviewing API server logs (if needed) to confirm that it loaded the encryption configuration.
