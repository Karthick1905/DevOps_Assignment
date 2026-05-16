# Task 2 — Secret Isolation & Security

The previous design used one shared Kubernetes Secret named `app-env`, which is unsafe in a shared-cluster SaaS model. This solution creates one GCP Secret Manager secret per tenant and syncs only that tenant's credentials into the tenant namespace using External Secrets Operator.

## Attack Prevented by Scoped IAM

By granting `roles/secretmanager.secretAccessor` only on `tenant-acme-corp-credentials`, a compromised tenant pod can read only its own database credentials. If the IAM binding were project-wide, the same compromised workload could read credentials for all tenants and create a cross-tenant data breach. Secret-level IAM limits blast radius and follows least privilege.

## Why NetworkPolicy Alone Is Not Enough

NetworkPolicy only controls pod network traffic. It does not stop a workload from using cloud IAM permissions, mounted credentials, or Kubernetes API permissions to read secrets. Shared-cluster tenant isolation requires multiple layers: namespace separation, RBAC, per-tenant secrets, Workload Identity, secret-scoped IAM, External Secrets Operator, and egress restrictions.
