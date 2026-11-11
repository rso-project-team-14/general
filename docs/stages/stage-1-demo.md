# Stage 1: Basic demo

<!-- sha256: 4c949e1306cf4a2ae8ff76e4869d377064e4f96884cd202aa9e67ed2a1c9927a -->

Back to [plan.md](../../plan.md).

## Goal

Verify that the whole setup works in the cloud environment. There is **no Butterfly Give business logic** in this stage. Every service only starts and answers basic API requests, and the whole thing runs in the cloud.

## Scope

### In scope
- Four Go services (`company-membership`, `challenge`, `participation`, `donation-impact`), each with:
  - `GET /health/started`: the service finished starting.
  - `GET /health/ready`: can reach its own database (PostgreSQL, or MongoDB for `challenge`). RabbitMQ is not checked in this stage.
  - `GET /health/live`: process is alive.
  - `GET /api/v1/ping`: returns a static JSON response with the service name, version, and time, for example `{"service": "participation", "version": "0.1.0", "time": "..."}`.
- Frontend page that calls `/api/v1/ping` on all four services and shows each response (green or red per service).
- A managed PostgreSQL service with three logical databases (`company_db`, `participation_db`, `impact_db`) and a managed MongoDB service with `challenge_db`, one database per service, all empty.
- Docker image for each service and for the frontend.
- Deployment to the cloud environment (AKS, with Helm and a basic GitHub Actions pipeline), so the page is reachable from the internet and shows all four services answering.

### Out of scope
- RabbitMQ. It is not set up in this stage.
- Everything else: authentication, companies, challenges, participation, donations, impact, events, business rules, database tables, seed data, OpenAPI beyond the ping and health endpoints.

## Checklist

- [ ] The four service repositories and the `frontend` repository set up as described in `plan.md` 1.4
- [ ] Each service responds on `/health/started`, `/health/ready`, `/health/live`, and `/api/v1/ping`
- [ ] `/health/ready` fails when the service's own database is unreachable
- [ ] Frontend page shows the ping result for all four services
- [ ] Docker images build for all services and the frontend
- [ ] Helm deploys the whole system into AKS
- [ ] GitHub Actions builds the images and deploys on merge to main
- [ ] The deployed page shows all four services answering from the cloud
