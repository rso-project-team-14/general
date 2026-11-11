# Stage 1: Basic demo

<!-- sha256: d190f1cfb04404974203c606358dd4065816616c3bdda1fe1193a70ea2ea0c30 -->

Back to [plan.md](../../plan.md). Next stage: [Stage 2](stage-2-database-and-calls.md).

## Goal

Verify that the Kubernetes cluster and the APIs work. The frontend and the backend run in the cloud, and the frontend page calls the APIs and shows the answers. There is **no Butterfly Give business logic**, **no database**, and **no calls from one service to another** in this stage. The database and the calls come in Stage 2.

This stage also starts following the structure of a Go service that is defined in `plan.md` section 1.4, so the services already have the shape they will keep later. Only the directories needed now are created (`cmd`, `config`, `domain`, and `http`). The `store`, `client`, and `migrations` directories are added in Stage 2, next to them, without reorganizing anything.

## Who does what

- **Agents** implement only the code: the four Go services (the structure from `plan.md` section 1.4, the endpoints, and the tests) and the frontend page.
- **The team** does all the deployment itself, to learn it: the Docker images, the Helm charts, the AKS cluster, the GitHub Actions pipeline, and deploying and checking everything in the cloud.
- An agent working on this stage does not do deployment work. It does not write or change Dockerfiles, Helm charts, pipeline files, or cluster configuration.

## Scope

### In scope
- Four Go services (`company-membership`, `challenge`, `participation`, `donation-impact`), each with:
  - `GET /health/started`: the service finished starting.
  - `GET /health/ready`: the service can handle requests. With no database or outgoing calls yet, it succeeds once the service has started.
  - `GET /health/live`: process is alive.
  - `GET /api/v1/ping`: returns a static JSON response with the service name, version, and time, for example `{"service": "participation", "version": "0.1.0", "time": "..."}`.
- The structure of a Go service from `plan.md` section 1.4, created in all four services. In this stage the logic only builds the ping answer.
- A `Makefile` in each Go service with the `build` and `test` targets from `plan.md` section 1.4.
- Small tests of the logic and the handlers (see "Tests" below).
- Frontend page that calls the ping endpoint of each of the four services through the gateway (the paths are in `plan.md` section 1.10) and shows each response (green or red per service).
- Done by the team: a Docker image for each service and for the frontend.
- Done by the team: deployment to the cloud environment (AKS, with Helm and a basic GitHub Actions pipeline), so the page is reachable from the internet and shows all four services answering.

### Out of scope
- Databases. No service connects to a database in this stage, so there is no `store`.
- Calls from a service to another service or to outside. There is no `client` in this stage.
- RabbitMQ. It is not set up in this stage.
- Everything else: authentication, companies, challenges, participation, donations, impact, events, business rules, database tables, seed data, OpenAPI beyond the ping and health endpoints.

## Tests

The tests in this stage are small and need no database, no RabbitMQ, and no network. There is no database and no client in this stage, so there is nothing to mock. They check that the structure works:

- A test of `domain` that checks the ping answer.
- A test of each `http` handler with a standard test HTTP server, checking the status code and the shape of the JSON.

`make test` runs all of them. The Makefile is defined in `plan.md` section 1.4.

## Checklist

Implementation (agents):

- [ ] The four service repositories and the `frontend` repository set up as described in `plan.md` 1.4
- [ ] Each service has the structure from `plan.md` section 1.4 for what exists in this stage, with the logic and the HTTP side in separate directories
- [ ] Each service responds on `/health/started`, `/health/ready`, `/health/live`, and `/api/v1/ping`
- [ ] Each service has a `Makefile` with the `build` and `test` targets, and `make build` produces the binary
- [ ] Tests exist for the logic and the handlers, and `make test` passes with no database or RabbitMQ running
- [ ] Frontend page shows the ping result for all four services

Deployment (the team):

- [ ] Docker images build for all services and the frontend
- [ ] Helm deploys the whole system into AKS
- [ ] GitHub Actions builds the images, runs `make test`, and deploys on merge to main
- [ ] The deployed page shows all four services answering from the cloud
