# Stage 1: Basic demo

<!-- sha256: ae2142277b521c6ac3b3fb93ab82e64de56950391bb79c1f914fb061b3c2971a -->

Back to [plan.md](../../plan.md).

## Goal

Verify that the whole setup works in the cloud environment. There is **no Butterfly Give business logic** in this stage, and **no frontend**: this stage is the backend only. Every service only starts and answers basic API requests, and the whole thing runs in the cloud.

## Scope

### In scope
- Four Go services (`company-membership`, `challenge`, `participation`, `donation-impact`), each with:
  - `GET /health/started`: the service finished starting.
  - `GET /health/ready`: can reach its own database (PostgreSQL, or MongoDB for `challenge`) and RabbitMQ.
  - `GET /health/live`: process is alive.
  - `GET /api/v1/ping`: returns a static JSON response with the service name, version, and time, for example `{"service": "participation", "version": "0.1.0", "time": "..."}`.
- A managed PostgreSQL service with three logical databases (`company_db`, `participation_db`, `impact_db`) and a managed MongoDB service with `challenge_db`, one database per service, all empty.
- One RabbitMQ instance (hosting still to be decided).
- Docker image for each service.
- Deployment to the cloud environment (AKS, with Helm and a basic GitHub Actions pipeline), so the ping endpoints of all four services can be called from outside the cluster and answer.

### Out of scope
- The frontend. It is not implemented in this stage.
- Everything else: authentication, companies, challenges, participation, donations, impact, events, business rules, database tables, seed data, OpenAPI beyond the ping and health endpoints.

## Checklist

- [ ] The four service repositories set up as described in `plan.md` 1.4 (the location of the deployment files is open, see `plan.md` 1.12 item 13)
- [ ] Each service responds on `/health/started`, `/health/ready`, `/health/live`, and `/api/v1/ping`
- [ ] `/health/ready` fails when the service's own database or RabbitMQ is unreachable
- [ ] Docker images build for all four services
- [ ] Helm deploys all four services into AKS
- [ ] GitHub Actions builds the images and deploys on merge to main
- [ ] The ping endpoint of each service answers when called from outside the cluster

## Open decisions this stage depends on

- Plan 1.12 item 2 (RabbitMQ hosting, and which managed products are used for PostgreSQL and MongoDB).
- Plan 1.12 item 3 (infrastructure as code or Azure CLI scripts).
