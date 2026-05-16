# TenantHub DevOps Technical Assignment

This repository contains a production-oriented design for onboarding and isolating tenants in a shared GKE-based SaaS platform.

The assignment asks for three pillars: tenant provisioning, secret isolation/security, and infra change visibility. The solution is written as code and does not require a live cloud account.

## Repository Structure

```text
.
├── tenants.yaml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/tenant/
├── kubernetes/base/
│   ├── namespace.yaml
│   ├── serviceaccount.yaml
│   ├── role.yaml
│   ├── rolebinding.yaml
│   ├── externalsecret.yaml
│   ├── networkpolicy.yaml
│   └── kustomization.yaml
├── .github/workflows/
│   ├── tenant-provision.yml
│   └── pr-diff.yml
├── argocd/
│   └── argocd-notifications-cm.yaml
├── task1/plan.txt
├── task2/README.md
└── task3/kustomize-output.txt
```

## Assumptions

- A GKE cluster already exists.
- A Cloud SQL PostgreSQL instance already exists.
- External Secrets Operator is already installed in the cluster.
- ArgoCD is already installed and managing the Kubernetes manifests.
- The solution is assessed for code quality, idempotency, least privilege, and documentation.

## Task 1 — Tenant Provisioning

A new tenant named `acme-corp` is added in `tenants.yaml`. The GitHub Actions workflow reads this file and provisions the tenant using Terraform and Kubernetes manifests.

Terraform provisions:

- A dedicated PostgreSQL database for the tenant.
- A dedicated PostgreSQL user.
- A tenant-specific GCP Secret Manager secret.
- A tenant-specific GCP service account.
- Secret-level IAM access for that service account.

Kubernetes provisions:

- Namespace: `acme-corp`
- ServiceAccount: `acme-corp-sa`
- Role with read-only access to tenant-owned secrets only.
- RoleBinding to bind the Role to the ServiceAccount.

## Idempotency

The workflow is safe to run more than once for the same tenant because Terraform is declarative and tracks resources through state. If the PostgreSQL database, user, secret, service account, and IAM binding already match the desired configuration, Terraform shows no changes. Kubernetes `kubectl apply` is also declarative, so applying the same Namespace, ServiceAccount, Role, and RoleBinding repeatedly updates only drifted fields and does not create duplicate resources.

## Scaling to 50 Tenants

To support 50 tenants without editing the workflow, each tenant can be added as a new entry in `tenants.yaml`. Terraform can use `for_each` over the tenant map, and the GitHub Actions workflow can remain generic. The workflow should detect tenant rows, generate the required Terraform variable input and Kubernetes overlays, then open a pull request. This keeps onboarding repeatable and avoids manually editing CI/CD logic per tenant.

## Task 2 — Secret Isolation & Security

Each tenant receives a separate GCP Secret Manager secret, for example `tenant-acme-corp-credentials`. The Kubernetes ServiceAccount is mapped to a tenant-specific GCP service account using Workload Identity. The GCP service account receives `roles/secretmanager.secretAccessor` only on that tenant secret, not the full project.

External Secrets Operator syncs the GCP Secret Manager value into the tenant namespace as a Kubernetes Secret. A NetworkPolicy restricts tenant pod egress to only cluster DNS and the tenant database CIDR.

## Why Scoped IAM Matters

If a tenant workload is compromised, secret-level IAM prevents the attacker from reading credentials belonging to other tenants. If the service account had project-wide Secret Manager access, one compromised pod could enumerate or read all tenant secrets and cause cross-tenant data exposure. Scoping access to a single secret follows least privilege and reduces the blast radius.

## Why NetworkPolicy Alone Is Not Enough

NetworkPolicy controls network traffic, but it does not control cloud IAM permissions or Kubernetes API permissions. A pod blocked by network rules could still abuse overly broad IAM permissions or mounted credentials to read secrets through cloud APIs. In a shared-cluster SaaS model, strong isolation requires multiple layers: namespace isolation, Kubernetes RBAC, Workload Identity, scoped IAM, secret separation, admission controls, and network policies.

## Task 3 — Infra Change Visibility

The PR diff workflow runs `kustomize build` on both the PR branch and the `main` branch, compares the rendered manifests, and posts the diff as a pull request comment. This allows reviewers to see actual Kubernetes resource changes before merging.

## Example Mistake Caught by PR Diff

A developer accidentally removes the `app` label from a Kubernetes Deployment template while modifying tenant manifests. Since the Service selector depends on that label, production traffic would stop routing to the pods after deployment. The PR diff would clearly show the label removal in the rendered manifest, allowing the reviewer to catch the issue before it reaches production.

## ArgoCD Alerting

The ArgoCD notifications ConfigMap sends Slack alerts when any Application becomes `Degraded` or `OutOfSync`. The alert contains the app name, environment, current status, and a link to the ArgoCD UI so the team can investigate quickly.
