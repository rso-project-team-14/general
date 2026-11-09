# Stage 1: Basic demo

Back to [plan.md](../../plan.md).

## Goal

Verify that the whole setup works in the cloud environment. There is **no Butterfly Give business logic** in this stage. Every service only starts and answers basic API requests, and the whole thing runs in the cloud.

## Scope

### In scope
- Four Go services (`company-membership`, `challenge`, `participation`, `donation-impact`), each with:
  - `GET /healthz`: process is alive.
  - `GET /readyz`: can reach its own database (PostgreSQL, or MongoDB for `challenge`) and RabbitMQ.
  - `GET /api/v1/ping`: returns a static JSON response with the service name, version, and time, for example `{"service": "participation", "version": "0.1.0", "time": "..."}`.
- Frontend page that calls `/api/v1/ping` on all four services and shows each response (green or red per service).
- One PostgreSQL instance with three logical databases (`company_db`, `participation_db`, `impact_db`) and one MongoDB instance with `challenge_db`, one database per service, all empty.
- One RabbitMQ instance.
- Docker image for each service and for the frontend.
- Deployment to the cloud environment (AKS, with Helm and a basic GitHub Actions pipeline), so the page is reachable from the internet and shows all four services answering.

### Out of scope
- Everything else: authentication, companies, challenges, participation, donations, impact, events, business rules, database tables, seed data, OpenAPI beyond the ping and health endpoints.

## Checklist

- [ ] The four service repositories and the frontend repository set up as described in `plan.md` 1.4 (location of the frontend is open, see `plan.md` 1.12 item 12)
- [ ] Each service responds on `/healthz`, `/readyz`, and `/api/v1/ping`
- [ ] `/readyz` fails when the service's own database or RabbitMQ is unreachable
- [ ] Frontend page shows the ping result for all four services
- [ ] Docker images build for all services and the frontend
- [ ] Helm deploys the whole system into AKS
- [ ] GitHub Actions builds the images and deploys on merge to main
- [ ] The deployed page shows all four services answering from the cloud

## Open decisions this stage depends on

- Plan 1.12 item 2 (data services in AKS: in-cluster or Azure managed).
- Plan 1.12 item 3 (infrastructure as code or Azure CLI scripts).
