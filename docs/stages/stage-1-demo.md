# Stage 1: Basic demo

<!-- sha256: dd9053efa0211b771d308830c381b6da5e7cc2b4dbaeacffbf190092edbd06b4 -->

Back to [plan.md](../../plan.md).

## Goal

Verify that the whole setup works in the cloud environment. There is **no Butterfly Give business logic** in this stage. Every service only starts and answers basic API requests, and the whole thing runs in the cloud.

This stage also starts following the structure of a Go service that is defined in `plan.md` section 1.4. The Go services get, already now, the shape they will keep later, with their code split into separate directories. The structure is checked with a few mock tests, so that later stages add endpoints and logic into it without reorganizing anything.

## Scope

### In scope
- Four Go services (`company-membership`, `challenge`, `participation`, `donation-impact`), each with:
  - `GET /health/started`: the service finished starting.
  - `GET /health/ready`: can reach its own database (PostgreSQL, or MongoDB for `challenge`). RabbitMQ is not checked in this stage.
  - `GET /health/live`: process is alive.
  - `GET /api/v1/ping`: returns a static JSON response with the service name, version, and time, for example `{"service": "participation", "version": "0.1.0", "time": "..."}`.
- The structure of a Go service from `plan.md` section 1.4, created in all four services. In this stage the logic only builds the ping answer, and the database side only opens the connection and provides the check used by `/health/ready`.
- Mock tests that check the structure (see "Mock tests" below).
- Frontend page that calls `/api/v1/ping` on all four services and shows each response (green or red per service).
- A managed PostgreSQL service with three logical databases (`company_db`, `participation_db`, `impact_db`) and a managed MongoDB service with `challenge_db`, one database per service, all empty.
- Docker image for each service and for the frontend.
- Deployment to the cloud environment (AKS, with Helm and a basic GitHub Actions pipeline), so the page is reachable from the internet and shows all four services answering.

### Out of scope
- RabbitMQ. It is not set up in this stage.
- Everything else: authentication, companies, challenges, participation, donations, impact, events, business rules, database tables, seed data, OpenAPI beyond the ping and health endpoints.

## Mock tests

The tests in this stage are small and need no database, no RabbitMQ, and no network. They check that the structure works:

- A test of `domain` that checks the ping answer.
- A test of each `http` handler with a standard test HTTP server, checking the status code and the shape of the JSON.
- A test of `/health/ready` with a mock of the `store` check, once reporting the database as reachable and once as unreachable.

**The database and the client are mocked.** In every test the `store` and the `client` are replaced by mocks that implement the interfaces defined by `domain`. A test never uses a real database or makes a real outgoing call. This stage has no outgoing calls yet, so only the mock database is needed now. The first mock client comes with the first outgoing call.

`go test ./...` runs all of them.

## Checklist

- [ ] The four service repositories and the `frontend` repository set up as described in `plan.md` 1.4
- [ ] Each service has the structure from `plan.md` section 1.4, with the logic, the HTTP side, and the database side in separate directories
- [ ] Mock tests exist for the logic, the handlers, and the readiness check, with the database and the client mocked, and `go test ./...` passes with no database or RabbitMQ running
- [ ] `go test ./...` runs in the GitHub Actions pipeline
- [ ] Each service responds on `/health/started`, `/health/ready`, `/health/live`, and `/api/v1/ping`
- [ ] `/health/ready` fails when the service's own database is unreachable
- [ ] Frontend page shows the ping result for all four services
- [ ] Docker images build for all services and the frontend
- [ ] Helm deploys the whole system into AKS
- [ ] GitHub Actions builds the images and deploys on merge to main
- [ ] The deployed page shows all four services answering from the cloud
