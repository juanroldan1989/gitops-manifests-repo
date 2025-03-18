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
aws ssm get-parameter --name "/greeter-saver/DB_URL" --with-decryption

{
  "Parameter": {
    "Name": "/greeter-saver/DB_URL",
    "Type": "SecureString",
    "Value": "postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com:5432/mydatabase",
    "Version": 1,
    "LastModifiedDate": "2025-03-19T22:25:14.345000+01:00",
    "ARN": "arn:aws:ssm:<region-id>:<account-id>:parameter/greeter-saver/DB_URL",
    "DataType": "text"
  }
}
```

## 6. Provision Apps within K8S Cluster

- Validate `argocd` and `argo-rollouts` are provisioned -> [steps](/argocd/README.md)

- Then provision apps:

```bash
kubectl apply -f argocd/apps/greeter-saver-app.yaml
kubectl apply -f argocd/apps/name-app.yaml
kubectl apply -f argocd/apps/greeting-app.yaml
```

- Removing the apps: Use ArgoCD UI to delete associated infrastructure resources through `foreground` deletion.

## 7. Secret values

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

## 8. AWS Secrets Store CSI Driver

- https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation

- https://github.com/aws/secrets-store-csi-driver-provider-aws?tab=readme-ov-file

- Deployment Example with Secrets Store CSI Driver:
https://github.com/kubernetes-sigs/secrets-store-csi-driver/blob/main/test/bats/tests/vault/deployment-synck8s.yaml

### Setup

1. Install CSI Driver:

```bash
helm repo add csi-secrets-store https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update
helm install csi-secrets-store csi-secrets-store/secrets-store-csi-driver --namespace kube-system
```

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
    # Specify the region if necessary
    region: <region-id>
    objects: |
      - objectName: "/greeter-saver/DB_URL"
        objectType: "ssmparameter"
  secretObjects:
    - secretName: greeter-saver-secret
      type: Opaque
      data:
        - objectName: "/greeter-saver/DB_URL"
          key: database-url
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
