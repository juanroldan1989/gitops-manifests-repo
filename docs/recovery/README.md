# Disaster Recovery

This document outlines the steps and procedures required to fully restore the entire platform,

including `AWS Infrastructure`, `Kubernetes Cluster` and `Applications`

in the event of a catastrophic failure.

## Scenario

1. **Kubernetes Cluster Up and Running:** The platform is fully operational with AWS infrastructure, an EKS cluster (provisioned via Terraform/Terragrunt and Karpenter), and deployed applications.

2. **Cluster Crash:** The Kubernetes cluster fails in a way that recovery on the same cluster is not feasible (e.g.: severe control plane issues or irrecoverable corruption).

3. **Rapid Restoration:** The Platform Engineer leverages automated, GitOps-based, and infrastructure-as-code procedures to restore the entire setup within minutes.

## Backup procedures

### Frequency

1. **Automation:** Backup procedures should be automated using CI/CD pipelines or scheduled jobs.

2. **Suggested Frequency:** Choose a frequency based on our Recovery Point Objectives (RPO). Common schedules include:

- Daily: For critical, rapidly changing data.
- Weekly/Bi-Weekly: For less volatile environments.
- Monthly: For archival or compliance purposes.

### Kubernetes Cluster

While `Terraform/Terragrunt` scripts are in place to provision the EKS cluster (and its supporting components like Karpenter), we should also consider:

- Configuration Backup: Back up Kubernetes manifests (Deployments, Services, etc.) as these are stored in our Git repositories.

- Cluster State Data: Use tools like `Velero` to back up persistent volumes `(PV)` and cluster state (e.g., `Custom Resource Definitions`, `Secrets`). `Velero` integrates with `AWS S3` for backup storage.

### Data

1. **Backup Data to AWS S3:** Identify which data requires backups:

- Application Data stored in `databases`.
- Persistent Volume Claims `(PVCs)` used by `stateful` applications.
- `Logs` and `audit trails` if not stored in a centralized logging solution.
- `Configuration snapshots` (if applicable) for stateful workloads.

2. **Backup Automation:**

- Use `scheduled` jobs (e.g.: `CronJobs` or `AWS Data Lifecycle Manager`) to automatically back up the data to a secure `S3` bucket.
- `Encrypt` and `version` the backups to ensure data integrity and security.

### DNS routes

1. **Backing Up DNS:** Since our DNS records are hosted in AWS Route 53, we can:

- `Export` DNS configurations regularly using `AWS CLI` commands or third-party tools.
- Use `infrastructure-as-code` (Terraform) to manage DNS records, which means our `Route 53` configuration is already `version-controlled` in our Terraform scripts.

2. **Recommendations:**

If our DNS configuration is managed via Terraform, ensure that:

- The Terraform `state` files are backed up (e.g.: in a secure `S3` bucket with `versioning` enabled).
- Regular exports or snapshots of the DNS configuration are maintained for rapid restoration if needed.

## Restoring procedures

### Kubernetes Cluster

1. **Restoration with Infrastructure as Code:** Since our `EKS` cluster is provisioned via Terraform/Terragrunt:

- Run our `Terraform` scripts to `re-create` the `cluster` and `network` infrastructure.
- After the cluster is available, use `ArgoCD` to re-apply `Kubernetes` `manifests` stored in `Git.`

2. **Additional Considerations:**

- Ensure that any `persistent volume claims` are **reattached or restored from our backup solution** (e.g., Velero).
- Validate that all `CRDs` and third-party integrations are re-installed.

### Data

1. **Automated Data Restoration:** For data stored in AWS S3:

- Use `Velero` (or a similar backup/restore tool) to restore `persistent volumes` and critical data.

- If we have database backups, use `automated` scripts or `database-native` tools to restore the data to our running instances.

2. **Steps for Data Restore:**

- `Trigger` Restore: Initiate restore from `Velero` or other backup tools.
- `Verify Data Integrity`: Ensure that the data restored is consistent with wer last known good backup.
- `Automate and Monitor`: Integrate restore verification steps in wer CI/CD pipeline to confirm successful recovery.

### DNS routes

1. **Restoration Procedures:** If DNS routes need to be restored:

- Using Terraform: Reapply the `Terraform` configuration for `Route 53`. Since the DNS records are defined as code, running your Terraform scripts should automatically re-create them.

- `Manual Export/Import`: If you maintain periodic exports, use the `AWS CLI` or the Route 53 console to import the DNS records back.

2. **Validation:** After restoration, perform health checks to ensure that DNS propagation is complete and that traffic is being routed correctly.

## Best Practices

1. **Test Your DR Plan Regularly:** Run disaster recovery drills periodically to validate your procedures and ensure that the team is familiar with the process.

1. **Documentation & Runbooks:** Maintain detailed runbooks for each recovery step, including commands, expected outputs, and troubleshooting tips.

1. **Monitoring & Alerts:** Implement robust monitoring and alerting (e.g., via CloudWatch, Prometheus, or similar tools) to quickly detect incidents and trigger automated recovery procedures.

1. **Secure Backup Storage:** Ensure that all backups (Terraform state files, Velero snapshots, DNS exports) are stored in a secure, version-controlled manner with proper access controls.

1. **Continuous Improvement:** After each DR exercise or actual incident, review the process, identify any gaps, and update the plan accordingly.

## References

https://www.youtube.com/watch?v=OzoC-wGfBnw&list=WL&index=43
