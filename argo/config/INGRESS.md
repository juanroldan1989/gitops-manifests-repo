# Setup ACM Certificate for ALB

- Create and use a self-signed certificate with AWS Certificate Manager (ACM)

- Allowing access to ArgoCD server securely via HTTPS without needing a custom domain.

## 1. Generate a `Self-Signed` certificate locally

You can use OpenSSL to create a self-signed certificate.

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout selfsigned.key \
  -out selfsigned.crt \
  -subj "/CN=argocd.local"
```

Explanation:
- `-x509`: Generates a self-signed certificate.
- `-nodes`: Creates a key without a passphrase.
- `-days 365`: The certificate is valid for 365 days.
- `-newkey rsa:2048`: Generates a new RSA key of 2048 bits.
- `-subj "/CN=argocd.local"`: Sets the Common Name (CN) to argocd.local (you can use any placeholder name since this is for testing).

## 2. Import the Self-Signed Certificate into AWS ACM

Before importing, ensure you have the `AWS CLI` configured with appropriate credentials.

Use the following command to import your certificate:

```bash
aws acm import-certificate \
  --certificate file://selfsigned.crt \
  --private-key file://selfsigned.key \
  --region <your-region>
```

- Replace `<your-region>` with the AWS region where your ALB is running (for example, `us-west-2`).

- Note: `ACM` will accept imported self-signed certificates.

- However, browsers won’t trust them by default, so you might see a warning when accessing the ALB.

- For a sample or internal project, this is usually acceptable.

- Once imported, note the returned Certificate ARN; you’ll need it for the next step.

## 3. Configure Your ALB Ingress to Use the Certificate

Update your ALB Ingress YAML to include the certificate ARN and enforce HTTPS.

```yaml
# ingress.yaml
...
alb.ingress.kubernetes.io/certificate-arn: <your-certificate-arn>
...
```

## 4. Access the ALB

- Once the ALB is provisioned and the certificate is attached, access your `ArgoCD` server using the `ALB’s DNS name` over HTTPS.

- Since the certificate is self-signed, your browser will likely warn you about an untrusted connection.

- You can bypass this warning for testing purposes.
