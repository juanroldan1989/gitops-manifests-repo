# Greeter Saver App

## 1. Provision Infrastructure

```bash
cd infrastructure/environments/prod

./infra-management.sh apply
```

- Note `VPC` ID and `private` subnet IDs.

## 2. Create a DB Subnet Group

- `Private Subnets:` Identify the subnet `IDs` in your `VPC` that are appropriate for hosting your RDS instance (usually private subnets). `subnet-abc` and `subnet-def`.

- `RDS` needs a `DB subnet group` to know **which subnets in your VPC** it can use.

- Create `DB subnet group` with your chosen subnets:

```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name mydbsubnetgroup \
  --db-subnet-group-description "DB Subnet group for greeter-saver RDS in new VPC" \
  --subnet-ids subnet-08b3344b03208cc6c subnet-0aa04b09945f3efd2
```

### Clarification

- DB Subnet Group: It should include private subnets in your VPC where it makes sense to run your RDS instance (typically subnets with no direct internet access).

- EKS Worker Nodes: They need to be in subnets that have network connectivity to the subnets specified in the DB subnet group. They do not have to be the same subnets, but they must be able to reach each other.

## 3. Setup Database Security Group

- Setup security group for RDS instance:

```bash
aws ec2 create-security-group \
  --group-name rds-greeter-saver-sg \
  --description "Security group for greeter-saver RDS instance" \
  --vpc-id vpc-0b98f5c35c101529d
```

- Save security group ID returned afterwards:

```bash
{
  "GroupId": "sg-0865ebbdd0753eacd",
  "SecurityGroupArn": "arn:aws:ec2:<region-id>:<account-id>:security-group/sg-0865ebbdd0753eacd"
}
```

- Allow inbound connections from your `EKS` worker subnets. Assume your worker subnet CIDRs are, for example, `10.0.2.0/24` and `10.0.3.0/24`:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0865ebbdd0753eacd \
  --protocol tcp \
  --port 5432 \
  --cidr 10.0.0.0/19

aws ec2 authorize-security-group-ingress \
  --group-id sg-0865ebbdd0753eacd \
  --protocol tcp \
  --port 5432 \
  --cidr 10.0.32.0/19
```

## 4. Provision RDS instance

```bash
aws rds create-db-instance \
  --db-instance-identifier greeter-saver-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --allocated-storage 20 \
  --master-username myuser \
  --master-user-password mypassword \
  --db-name mydatabase \
  --no-publicly-accessible \
  --vpc-security-group-ids sg-0865ebbdd0753eacd \
  --db-subnet-group-name mydbsubnetgroup \
  --backup-retention-period 7 \
  --storage-encrypted
```

## 5. Retrieve the RDS Endpoint and Save in SSM Parameter Store

### Retrieve `RDS endpoint`

```bash
aws rds describe-db-instances \
  --db-instance-identifier greeter-saver-db \
  --query "DBInstances[0].Endpoint.Address" \
  --output text
```

```bash
greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com
```

### Construct your full DATABASE_URL

- Format:

```bash
postgresql://myuser:mypassword@<endpoint>:5432/mydatabase
```

- For our example:

```bash
postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com:5432/mydatabase
```

### Store `DATABASE_URL` in `SSM` Parameter Store:

```bash
aws ssm put-parameter \
  --name "/greeter-saver/DB_URL" \
  --value "postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com:5432/mydatabase" \
  --type SecureString \
  --overwrite
```

- This stores your secret in `SSM` (encrypted using your default `KMS` key).

- Validate secret has been stored properly:

```bash
aws ssm get-parameter --name "greeter-saver-database-url" --with-decryption

{
  "Parameter": {
    "Name": "greeter-saver-database-url",
    "Type": "SecureString",
    "Value": "postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.us-east-1.rds.amazonaws.com:5432/mydatabase",
    "Version": 1,
    "LastModifiedDate": "2025-03-19T22:25:14.345000+01:00",
    "ARN": "arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver-database-url",
    "DataType": "text"
  }
}
```

## 7. AWS Secrets Store CSI Driver

- https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation

- https://github.com/aws/secrets-store-csi-driver-provider-aws?tab=readme-ov-file

- Deployment Example with Secrets Store CSI Driver:
https://github.com/kubernetes-sigs/secrets-store-csi-driver/blob/main/test/bats/tests/vault/deployment-synck8s.yaml

1. Install CSI Driver:

```bash
helm repo add csi-secrets-store https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update
helm install csi-secrets-store csi-secrets-store/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::<account-id>:role/<CSI-Driver-Role>"
```

In this command, we:

- Enable the `syncSecret` feature.
- Set the `eks.amazonaws.com/role-arn` annotation on the `service account` used by the `CSI driver`.

2. Install the AWS Provider for the Secrets Store CSI Driver:

```bash
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws -n kube-system
```

3. Create Secret Provider class:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: ssm-db-credentials
  namespace: greeter-app
spec:
  provider: aws
  parameters:
    region: us-east-1 # Specify the region if necessary
    objects: |
      - objectName: "greeter-saver-database-url"
        objectType: "ssmparameter"
  secretObjects:
    - secretName: greeter-saver-secret
      type: Opaque
      data:
        - objectName: "greeter-saver-database-url"
          key: database-url
```

```bash
kubectl apply -f manifests/greeter-saver-app/ssm-secretproviderclass.yaml
```

4. Validate CSI Driver Logs and check for `"reconcile start"` and `"reconcile complete"` messages:

```bash
kubectl logs -f -n kube-system -l app=secrets-store-csi-driver
```

5. Validate `Service Account` resources have the correct `EKS` annotation:

- The annotation `eks.amazonaws.com/role-arn` is used to **bind an IAM role to a Kubernetes Service Account via IRSA (IAM Roles for Service Accounts)**.

- You need to add this annotation to any Service Account that must assume an AWS IAM role to access AWS resources:

-- **The CSI Driver’s Service Account:**

The service account used by the `Secrets Store CSI Driver` (usually in the `kube-system` namespace) must be annotated with the IAM role ARN that has permissions to access SSM (and other AWS APIs as needed).

-- **Your Application’s Service Account (if applicable):**

If your application also requires AWS access via IRSA (for example: if it accesses `S3`, `SSM`, or other services directly), then **its service account should also be annotated with the appropriate IAM role ARN**.

- If you’re only using the CSI driver to pull secrets from `SSM`, then the key resource to annotate is the CSI driver’s service account (e.g., `secrets-store-csi-driver` in the `kube-system` namespace). Ensure that this Service Account has an annotation like:

```bash
eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/<CSI-Driver-Role>
```

- This annotation tells AWS that **when the CSI driver pods assume this service account, they should be granted the permissions of the specified IAM role.**

- If your application pods (e.g.: `greeter-saver-app`) also need to access AWS services directly, then you should similarly annotate their Service Account (for example, greeter-saver-sa in the greeter-app namespace) with the appropriate IAM role ARN.

## 9. IAM Policy, IAM Role and Service Accounts

1. Create an IAM policy that grants the required permissions (for example, `ssm:GetParameter` and `ssm:GetParameters`). Save it as a JSON file (e.g., ssm-policy.json):

```bash
aws iam create-policy --policy-name GreeterSaverSSMPolicy --policy-document file://manifests/greeter-saver-app/ssm-policy.json
```

2. Create an IAM Role for the Service Account:

- Assuming your `EKS` cluster has an `OIDC` provider set up, create an **IAM role that can be assumed by your service account.**

```bash
aws eks describe-cluster --name prod-eks-cluster-a --query "cluster.identity.oidc.issuer" --output text

https://oidc.eks.us-east-1.amazonaws.com/id/9C4BEA34C8AC70FD78CDDD9D129FE9B0
```

3. Now, create the IAM role:

```bash
aws iam create-role --role-name GreeterSaverRole --assume-role-policy-document file://manifests/greeter-saver-app/trust-policy.json
```

4. Then attach the policy you created:

```bash
aws iam attach-role-policy --role-name GreeterSaverRole --policy-arn arn:aws:iam::<account-id>:policy/GreeterSaverSSMPolicy
```

5. Create a Service Account in Your Cluster:

- Create a service account for your `greeter-saver` app in the `greeter-app` namespace and annotate it with the `IAM` role ARN.

```bash
apiVersion: v1
kind: ServiceAccount
metadata:
  name: greeter-saver-sa
  namespace: greeter-app
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::<account-id>:role/GreeterSaverRole"
```

- Apply it:

```bash
kubectl apply -f greeter-saver-sa.yaml
```

## 8. Provision Apps within K8S Cluster

- Validate `argocd` and `argo-rollouts` are provisioned -> [steps](/argocd/README.md)

- Then provision apps:

```bash
kubectl apply -f argocd/apps/greeter-saver-app.yaml
kubectl apply -f argocd/apps/name-app.yaml
kubectl apply -f argocd/apps/greeting-app.yaml
```

- Removing the apps: Use ArgoCD UI to delete associated infrastructure resources through `foreground` deletion.

## 9. Secret values

- `ENV` variables (**sensitive** and **non-sensitive** ones) can be defined within a single block:

```bash
...
env:
  - name: NAME_SERVICE_URL
    value: "http://name:5001/name"
  - name: GREETING_SERVICE_URL
    value: "http://greeting:5002/greeting"
  - name: DATABASE_URL
    secret: true
    secret_name: "GREETER_SAVER_DATABASE_URL" # kept for reference only
    provider: "AWS_SSM"                       # kept for reference only

```

- Based on the above setup:

### For `non-sensitive` values

1. `NAME_SERVICE_URL` is passed directly as an inline value to the `deployment` K8S resource.
2. `GREETING_SERVICE_URL` is passed directly as an inline value to the `deployment` K8S resource.

### For `sensitive` values

```bash
  - name: DATABASE_URL
    secret: true
    secret_name: "GREETER_SAVER_DATABASE_URL" # kept for reference only
    provider: "AWS_SSM"                       # kept for reference only
```

1. `DATABASE_URL` is set through an external secrets provider (e.g.: AWS SSM).

2. Secret `aws-ssm-database-url` will automatically be created by the `application` Helm chart:

```bash
kubectl describe secret greeter-saver-secret -n greeter-app
Name:         greeter-saver-secret
Namespace:    greeter-app
Labels:       app.kubernetes.io/managed-by=Helm
Annotations:  meta.helm.sh/release-name: greeter-saver
              meta.helm.sh/release-namespace: greeter-app

Type:  Opaque

Data
====
database-url:  0 bytes
```

3. An **empty** value string will be populated for the secret. Allowing your external process (like the `AWS Secrets Store CSI Driver`) to populate it later.

- Kubernetes resource **names** must follow `RFC 1123`, which allows only lowercase alphanumeric characters, '-' and '.'

#### Validate Pod is accessing the AWS secret correctly

```bash
kubectl exec -it greeter-saver-deployment-5d4798df54-lzrk9 -n greeter-app -- ls /mnt/secrets-store
_greeter-saver_DB_URL

kubectl exec -it greeter-saver-deployment-5d4798df54-lzrk9 -n greeter-app -- cat /mnt/secrets-store/_greeter-saver_DB_URL
postgresql://myuser:mypassword@greeter-saver-db.xxxxxx.<region-id>.rds.amazonaws.com:5432/mydatabase%
```

#### IMPORTANT

**if we had used /greeter-saver/DB_URL** instead of **greeter-saver-database-url**:

1. The CSI driver is supposed to take the parameter from SSM (using objectName "/greeter-saver/DB_URL") and sync it into the Kubernetes Secret under the key "database-url".

2. The CSI driver’s **internal sanitization of the objectName** will adjust the `objectName` to `_greeter-saver_DB_URL`

3. So there will be a mismatch between what your `SecretProviderClass` expects and what the `CSI Driver` creates.

4. Then, CSI Driver logs will show:

```bash
kubectl logs -f -n kube-system -l app=secrets-store-csi-driver

...
E0322 12:07:55.866189       1 secretproviderclasspodstatus_controller.go:318] "failed to get data in spc for secret" err="file matching objectName /greeter-saver/DB_URL not found in the pod" spc="greeter-app/ssm-db-credentials" pod="greeter-app/greeter-saver-deployment-5846548fc8-bqlh8" secret="greeter-app/greeter-saver-secret" spcps="greeter-app/greeter-saver-deployment-5846548fc8-bqlh8-greeter-app-ssm-db-credentials"

I0322 12:08:06.106979       1 secretproviderclasspodstatus_controller.go:224] "reconcile started" spcps="greeter-app/greeter-saver-deployment-5846548fc8-bqlh8-greeter-app-ssm-db-credentials"
...
```

### Inspect `greeter-saver-deployment` and add CSI Secrets references through `volumeMounts`

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox-deployment
  labels:
    app: busybox
spec:
  replicas: 2
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      terminationGracePeriodSeconds: 0
      containers:
      - image: registry.k8s.io/e2e-test-images/busybox:1.29-4
        name: busybox
        imagePullPolicy: IfNotPresent
        command:
        - "/bin/sleep"
        - "10000"
        env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: foosecret
              key: username
        volumeMounts:
        - name: secrets-store-inline
          mountPath: "/mnt/secrets-store"
          readOnly: true
      volumes:
        - name: secrets-store-inline
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "vault-foo-sync"
```

### `greeter-saver-deployment` logs

```bash
...
Successfully assigned greeter-app/greeter-saver-deployment-74fb47d99d-swjhk to ip-10-0-16-182.ec2.internal
  Warning  FailedMount  2s (x9 over 2m10s)  kubelet            MountVolume.SetUp failed for volume "secrets-store-inline" : rpc error: code = Unknown desc = failed to mount secrets store objects for pod greeter-app/greeter-saver-deployment-74fb47d99d-swjhk, err: rpc error: code = Unknown desc = us-east-1: An IAM role must be associated with service account default (namespace: greeter-app)
```

This error means that:

- `Secrets Store CSI` driver’s AWS provider requires an IAM role to be associated with the `pod’s service account` so that it can call AWS APIs (e.g. `SSM:GetParameter`).

- Right now, your pod is using the `default` service account, which doesn’t have an associated IAM role.

- That is the reason an IAM Policy, IAM Role and Service Account have to be created.

- IAM Policy is associated with IAM Role.

- IAM Role is associated with Service Account.

- Service Account contains the right annotation for the EKS cluster.

- Deployments can now have this Service Account associated, so their pods will have the right permissions to access AWS resources.

### Validate IAM Role (EKS Worker Node) can access SSM

- Through AWS Console, check IAM role associated with EKS Worker nodes.

- Once you have the IAM role, review its attached policies to ensure that it allows the necessary SSM actions. The permissions typically needed include actions like:

```bash
  ssm:GetParameter
  ssm:GetParameters
  ssm:GetParameterHistory
  ssm:DescribeParameters
```

### Simulate Policy Evaluation

You can simulate whether the role has permission to access your SSM parameter using the AWS CLI's simulation feature. For example:

```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<account-id>:role/Karpenter-prod-eks-cluster-a-20250319204924635400000006 \
  --action-names ssm:GetParameter \
  --resource-arns arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver/DB_URL
```

```bash
{
  "EvaluationResults": [
    {
      "EvalActionName": "ssm:GetParameter",
      "EvalResourceName": "arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver/DB_URL",
      "EvalDecision": "allowed",
...
```

### Troubleshooting

- Try deleting `greeter-saver-secret` and provisioning `greeter-saver` app again.
