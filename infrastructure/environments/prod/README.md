# Greeter Saver App

![Screenshot 2025-03-22 at 20 40 02](https://github.com/user-attachments/assets/413e7e17-7116-46fa-a0f6-054225a58d61)

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
  --subnet-ids subnet-05e6acff19687ab27 subnet-0a16a8a82af9f31bc
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
  --vpc-id vpc-019d367acf18128eb
```

- Save security group ID returned afterwards:

```bash
{
  "GroupId": "sg-0fc642d186dc26347",
  "SecurityGroupArn": "arn:aws:ec2:<region-id>:<account-id>:security-group/sg-0fc642d186dc26347"
}
```

- Allow inbound connections from your `EKS` worker subnets. Assume your worker subnet CIDRs are, for example, `10.0.2.0/24` and `10.0.3.0/24`:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0fc642d186dc26347 \
  --protocol tcp \
  --port 5432 \
  --cidr 10.0.0.0/19

aws ec2 authorize-security-group-ingress \
  --group-id sg-0fc642d186dc26347 \
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
  --vpc-security-group-ids sg-0fc642d186dc26347 \
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
  --name "greeter-saver-database-url" \
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
    "Value": "postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com:5432/mydatabase",
    "Version": 1,
    "LastModifiedDate": "2025-03-19T22:25:14.345000+01:00",
    "ARN": "arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver-database-url",
    "DataType": "text"
  }
}
```

## 6. IAM Policy, IAM Role and Service Accounts

1. Create an IAM policy that grants the required permissions (for example, `ssm:GetParameter` and `ssm:GetParameters`). Save it as a JSON file (e.g., ssm-policy.json):

```bash
aws iam create-policy --policy-name GreeterSaverSSMPolicy --policy-document file://manifests/greeter-saver-app/ssm-policy.json
```

2. Create an IAM Role for the Service Account:

- Assuming your `EKS` cluster has an `OIDC` provider set up, create an **IAM role that can be assumed by your service account.**

```bash
aws eks describe-cluster --name prod-eks-cluster-a --query "cluster.identity.oidc.issuer" --output text

https://oidc.eks.<region-id>.amazonaws.com/id/A9BD6F8F6A7B1FF74CF0AE380EECF3BD
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

## 7. AWS Secrets Store CSI Driver

- https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation

- https://github.com/aws/secrets-store-csi-driver-provider-aws?tab=readme-ov-file

- Deployment Example with Secrets Store CSI Driver:
https://github.com/kubernetes-sigs/secrets-store-csi-driver/blob/main/test/bats/tests/vault/deployment-synck8s.yaml

- https://github.com/antonputra/tutorials/tree/main/lessons/079

1. Install CSI Driver:

```bash
helm repo add csi-secrets-store https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update
helm install csi-secrets-store csi-secrets-store/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::<account-id>:role/GreeterSaverRole"
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
    region: <region-id> # Specify the region if necessary
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
eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/GreeterSaverRole
```

- This annotation tells AWS that **when the CSI driver pods assume this service account, they should be granted the permissions of the specified IAM role.**

- If your application pods (e.g.: `greeter-saver-app`) also need to access AWS services directly, then you should similarly annotate their Service Account (for example, greeter-saver-sa in the greeter-app namespace) with the appropriate IAM role ARN.

6. Add Cluster Roles permissions to CSI Driver:

```bash
kubectl apply -f manifests/greeter-saver-app/csi-driver-cluster-role.yaml
clusterrole.rbac.authorization.k8s.io/secrets-store-csi-driver-role created
clusterrolebinding.rbac.authorization.k8s.io/secrets-store-csi-driver-binding created
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

- Kubernetes resource **names** must follow `RFC 1123`, which allows only lowercase alphanumeric characters, '-' and '.'

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

4. TODO:

1. For `local` development, `sensitive` values should be provisioned via a Kubernetes `Secret`.
2. For `cloud` deployment, `sensitive` values will be automatically stored in a **secret created by** the `CSI Driver`.
3. This means, for `cloud` deployments, we **should not create a Kubernetes Secret** via manifests. This way:

- `SecretProviderClass` will take care of handling the connection between AWS SSM Paramters (or Secrets Manager)
- `Deployment` resource will reference the required secret from AWS and place it within an `ENV` variable, e.g.: `DATABASE_URL`
- `CSI Driver` will manage `Secret` resources, so every Pod will have available the proper secret.

- Business logic for sensitive values declaration needs to be improved.

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

## 10. Validate data is stored properly

1. Find `ingress` URL and access it:

```bash
kubectl get ingress -A
NAMESPACE     NAME            CLASS   HOSTS   ADDRESS                                                                   PORTS   AGE
greeter-app   greeter-saver   alb     *       k8s-greetera-greeters-cb352b7b5c-1029811030.<region-id>.elb.amazonaws.com   80      154m
```

2. Trigger a couple of requests:

```bash
curl http://k8s-greetera-greeters-cb352b7b5c-1029811030.<region-id>.elb.amazonaws.com/greet
{"message":"Hello, Bob!"}

❯ curl http://k8s-greetera-greeters-cb352b7b5c-1029811030.<region-id>.elb.amazonaws.com/greet
{"message":"Hello, Charlie!"}

❯ curl http://k8s-greetera-greeters-cb352b7b5c-1029811030.<region-id>.elb.amazonaws.com/greet
{"message":"Hello, Alice!"}
...
```

3. Access RDS Instance from a temporal `debug-pod` and validate records stored properly:

```bash
kubectl run debug-pod --rm -it --image=postgres --namespace default -- bash

If you dont see a command prompt, try pressing enter.
root@debug-pod:/# psql -h greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com -U myuser -d mydatabase
Password for user myuser:
psql (17.4 (Debian 17.4-1.pgdg120+2), server 17.2)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off, ALPN: postgresql)
Type "help" for help.

mydatabase=> SELECT * FROM "greetings";

id |     message     |         created_at
----+-----------------+----------------------------
  1 | Hello, Daisy!   | 2025-03-22 19:20:30.995826
  2 | Greetings, Eve! | 2025-03-22 19:20:32.561708
  3 | Hey, Alice!     | 2025-03-22 19:20:33.10501
  4 | Hi, Alice!      | 2025-03-22 19:20:33.359021
  5 | Hi, Eve!        | 2025-03-22 19:20:33.633131
  6 | Hi, Eve!        | 2025-03-22 19:20:33.926945
  7 | Hi, Daisy!      | 2025-03-22 19:20:34.182778
  8 | Hi, Alice!      | 2025-03-22 19:20:34.423419
  9 | Hi, Eve!        | 2025-03-22 19:20:34.616599
 10 | Hello, Alice!   | 2025-03-22 19:20:39.819444
 11 | Hi, Alice!      | 2025-03-22 19:20:40.036685
 ...
```

### Troubleshooting `greeter-saver-deployment` logs

```bash
...
Successfully assigned greeter-app/greeter-saver-deployment-74fb47d99d-swjhk to ip-10-0-16-182.ec2.internal
  Warning  FailedMount  2s (x9 over 2m10s)  kubelet            MountVolume.SetUp failed for volume "secrets-store-inline" : rpc error: code = Unknown desc = failed to mount secrets store objects for pod greeter-app/greeter-saver-deployment-74fb47d99d-swjhk, err: rpc error: code = Unknown desc = <region-id>: An IAM role must be associated with service account default (namespace: greeter-app)
```

This error means that:

- `Secrets Store CSI` driver’s AWS provider requires an IAM role to be associated with the `pod’s service account` so that it can call AWS APIs (e.g. `SSM:GetParameter`).

- Right now, your pod is using the `default` service account, which doesn’t have an associated IAM role.

- That is the reason an IAM Policy, IAM Role and Service Account have to be created.

- IAM Policy is associated with IAM Role.

- IAM Role is associated with Service Account.

- Service Account contains the right annotation for the EKS cluster.

- Deployments can now have this Service Account associated, so their pods will have the right permissions to access AWS resources.

### Simulate Policy Evaluation

You can simulate whether the role has permission to access your SSM parameter using the AWS CLI's simulation feature. For example:

```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<account-id>:role/Karpenter-prod-eks-cluster-a-20250319204924635400000006 \
  --action-names ssm:GetParameter \
  --resource-arns arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver-database-url
```

```bash
{
  "EvaluationResults": [
    {
      "EvalActionName": "ssm:GetParameter",
      "EvalResourceName": "arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver-database-url",
      "EvalDecision": "allowed",
...
```
