# Stage 3: Cloud delivery

Back to [plan.md](../../plan.md). Previous stage: [Stage 2](stage-2-mvp.md).

## Goal

The MVP runs in Microsoft Azure Kubernetes Service (AKS). Images are built and pushed by GitHub Actions. Deployment is done with Helm. Configuration is separate from code. The system is observable enough to debug a failed donation flow in the cluster.

## Scope

### In scope
- Dockerfile per service (multi-stage, distroless or alpine runtime, non-root user).
- Dockerfile for the frontend (build, then nginx serving static files and proxying `/api/`).
- Azure resources: resource group, AKS cluster, container registry, and a PostgreSQL and RabbitMQ setup (plan 1.12 items 2 and 3).
- Helm charts: one per service, one umbrella chart, values per environment.
- Kubernetes Secrets for DB credentials, RabbitMQ credentials, and the JWT signing key.
- Ingress with TLS.
- GitHub Actions: pull request checks, build-and-push on merge to main, Helm deploy to AKS.
- Health probes wired to `/healthz` and `/readyz`.
- Basic observability: JSON logs from containers, request ID propagation, a dashboard or log query for the donation flow.
- Smoke test script run after each deploy.

### Out of scope
- Autoscaling policies beyond the default HPA, multi-region, disaster recovery.
- Load testing (possible later stage).

## Deliverables

| Item | Location |
|---|---|
| Dockerfiles | `services/*/Dockerfile`, `frontend/Dockerfile` |
| Helm charts | `deploy/helm/` |
| Azure setup script or IaC | `deploy/azure/` (decision in plan 1.12 item 3) |
| CI pull request workflow | `.github/workflows/ci.yml` |
| CD workflow | `.github/workflows/cd.yml` |
| Smoke test | `deploy/smoke/` |
| Runbook | this file, section "Runbook" below |

## Azure setup (default assumption)

1. Resource group `rg-butterfly-give` in one region.
2. Azure Container Registry `acrbutterflygive` (name to be confirmed, must be globally unique).
3. AKS cluster with a small node pool, managed identity, and ACR pull rights.
4. Ingress controller (nginx ingress) and cert-manager for TLS.
5. PostgreSQL and RabbitMQ: in-cluster through Helm for this stage (plan 1.12 item 2). Azure Database for PostgreSQL is the alternative if the course allows it.

## Helm design

- Umbrella chart `butterfly` with sub-charts `company-membership`, `challenge-campaign`, `participation`, `donation-impact`, `frontend`.
- Each sub-chart renders Deployment, Service, ConfigMap, and an optional Ingress path rule.
- Secrets are referenced by name. They are created outside Helm (by the CD workflow from GitHub environment secrets) so no secret value is in Helm values.
- Values files: `values.yaml` (defaults), `values-aks.yaml` (cloud), `values-local.yaml` (for local Kubernetes if used).

## CI/CD design

**Pull request workflow**
1. Go: `go vet`, `go test ./...` per changed service.
2. Frontend: `npm ci`, lint, unit tests, build.
3. OpenAPI: validate every file in `api/`.
4. Docker build for each changed service (no push).
5. Helm lint and `helm template` for the umbrella chart.

**Main branch workflow**
1. Repeat the checks above.
2. Log in to Azure using a federated credential (OIDC), not a stored password.
3. Build and push images, tagged with the commit SHA.
4. `helm upgrade --install` to the AKS cluster with the SHA tags.
5. Run the smoke test. Fail the workflow if it fails.

## Observability

- All services write JSON logs to stdout. AKS collects them through the default log pipeline.
- Each request carries `X-Request-ID`, and each RabbitMQ message carries it as a header, so one flow can be followed across services.
- A short runbook query lists how to find all log lines for one `X-Request-ID`.

## Runbook (to be filled during this stage)

- How to deploy manually: _TBD_
- How to roll back a Helm release: _TBD_
- How to inspect the RabbitMQ dead-letter queue: _TBD_
- How to rotate the JWT signing key: _TBD_

## Checklist

- [ ] Each service image builds and runs as non-root
- [ ] Frontend image serves the SPA and proxies `/api/` to the ingress
- [ ] Azure resources created (or script to create them committed)
- [ ] Helm umbrella chart installs the whole system into an empty namespace
- [ ] Secrets created by CD, not stored in the repo
- [ ] PR workflow runs green on a sample pull request
- [ ] Main branch workflow deploys to AKS
- [ ] Smoke test passes against the AKS deployment
- [ ] Health probes configured and passing
- [ ] Donation flow traceable by `X-Request-ID` in the cluster logs
- [ ] Runbook sections filled in
- [ ] Demo of the running cloud system recorded for the course

## Open decisions this stage depends on

- Plan 1.12 item 2 (data services in AKS): in-cluster assumed.
- Plan 1.12 item 3 (infrastructure as code): Azure CLI script assumed.
- Plan 1.12 item 1 (auth): carried over from Stage 2.
