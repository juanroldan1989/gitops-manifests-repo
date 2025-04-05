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
  --subnet-ids subnet-0bb918906fa71b188 subnet-0dd3effd3149d17a0
```

### Clarification

- **DB Subnet Group:** It should include private subnets in your VPC where it makes sense to run your RDS instance (typically subnets with no direct internet access).

- **EKS Worker Nodes:** They need to be in subnets that have network connectivity to the subnets specified in the DB subnet group. They do not have to be the same subnets, but they must be able to reach each other.

## 3. Setup Database Security Group

- Setup security group for RDS instance:

```bash
aws ec2 create-security-group \
  --group-name rds-greeter-saver-sg \
  --description "Security group for greeter-saver RDS instance" \
  --vpc-id vpc-0180963725a1c4383
```

- Save security group ID returned afterwards:

```bash
{
  "GroupId": "sg-0187c0e2d1cf8a5a9",
  "SecurityGroupArn": "arn:aws:ec2:<region-id>:<account-id>:security-group/sg-0187c0e2d1cf8a5a9"
}
```

- Allow inbound connections from your `EKS` worker subnets. Assume your worker subnet CIDRs are, for example, `10.0.2.0/24` and `10.0.3.0/24`:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-0187c0e2d1cf8a5a9 \
  --protocol tcp \
  --port 5432 \
  --cidr 10.0.0.0/19

aws ec2 authorize-security-group-ingress \
  --group-id sg-0187c0e2d1cf8a5a9 \
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
  --vpc-security-group-ids sg-0187c0e2d1cf8a5a9 \
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

### Store `DATABASE_URL` in `AWS Secrets Manager`

- We store secret as `key/value` pair:

```bash
aws secretsmanager create-secret \
  --name "greeter-saver-secret3" \
  --description "Greeter Saver Secret for App - Contains DATABASE_URL" \
  --secret-string '{"database-url":"postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com:5432/mydatabase"}'
```

- This stores your secret in `AWS Secrets Manager` (encrypted using your default `KMS` key).

- Validate secret has been stored properly:

```bash
aws secretsmanager get-secret-value \
  --secret-id "greeter-saver-secret3" \
  --query SecretString \
  --output text

{
  "ARN": "arn:aws:secretsmanager:<region-id>:<account-id>:secret:greeter-saver-secret3-oeItZY",
  "Name": "greeter-saver-secret3",
  "VersionId": "1a66cc26-ae3c-411a-af24-00a99ed4b9ea",
  "SecretString": "{\"database-url\":\"postgresql://myuser:mypassword@greeter-saver-db.cvzkxrydiye2.<region-id>.rds.amazonaws.com:5432/mydatabase\"}",
  "VersionStages": [
      "AWSCURRENT"
  ],
  "CreatedDate": "2025-04-05T10:18:21.916000+02:00"
}

```

## 6. Provision Apps within K8S Cluster

All steps automated within `/bootstrap-prod.sh --apps name-app greeting-app greeter-saver-app`.

## 7. Secret values

- Once AWS Secret has been created in AWS:

<img width="1301" alt="Screenshot 2025-03-29 at 19 06 18" src="https://github.com/user-attachments/assets/0e6228ab-4f87-48b7-8870-6859ed31c806" />

- `ENV` variables (**sensitive** and **non-sensitive** ones) can be defined within a single block:

```bash
...
env:
  - name: NAME_SERVICE_URL
    value: "http://name:5001/name"         # non-sensitive env var
  - name: GREETING_SERVICE_URL
    value: "http://greeting:5002/greeting" # non-sensitive env var
  - name: DATABASE_URL
    secret: true                           # if true, the value will be taken from an AWS secret
    secretName: greeter-saver-secret       # `name` of secret in AWS (K8S Secret automatically created with the same name)
    secretKey: database-url                # `key` of secret in AWS and `key` in Kubernetes secret (K8S Secret key automatically added within the secret)
```

- Based on the above setup:

### For `non-sensitive` values

1. `NAME_SERVICE_URL` is passed directly as an inline value to the `deployment` K8S resource.
2. `GREETING_SERVICE_URL` is passed directly as an inline value to the `deployment` K8S resource.

### For `sensitive` values

1. For `local` and `production` mode, AWS Secrets are **fetched and handled in the same way.**
2. [External Secrets Operator](/argo/ESO.md) makes this possible.

- For every `Deployment` resource created that contains `env` section with at least 1 variable with `secret: true` defined,
- A `Kubernetes Secret` resource is automatically created and managed by ESO.


## 8. Validate data is stored properly

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
