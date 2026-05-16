# Task 3 — Infra Change Visibility

The `pr-diff.yml` workflow renders Kubernetes resources from both the PR branch and `main` using `kustomize build`. It then posts the rendered diff as a PR comment so reviewers can see what will actually change in the cluster.

## Real Scenario

If a developer accidentally removes a Deployment label used by a Service selector, the application may become unreachable after deployment. The source YAML change may look small, but the rendered manifest diff will clearly show the label removal and allow reviewers to block the change before it reaches production.
