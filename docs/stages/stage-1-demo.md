# Stage 1: Basic demo

<!-- sha256: c87efa470d3fb7993b61dc73994c6a6c8ee2e33143cb67f60c66af2ceb4b8440 -->

Back to [plan.md](../../plan.md).

## Goal

Verify that the whole setup works in the cloud environment. There is **no Butterfly Give business logic** in this stage. Every service only starts and answers basic API requests, and the whole thing runs in the cloud.

This stage also creates the structure. The Go services get, already now, the shape they will keep later, with their code split into separate directories. The structure is defined here and checked with a few mock tests, so that later stages add endpoints and logic into it without reorganizing anything.

## Scope

### In scope
- Four Go services (`company-membership`, `challenge`, `participation`, `donation-impact`), each with:
  - `GET /health/started`: the service finished starting.
  - `GET /health/ready`: can reach its own database (PostgreSQL, or MongoDB for `challenge`). RabbitMQ is not checked in this stage.
  - `GET /health/live`: process is alive.
  - `GET /api/v1/ping`: returns a static JSON response with the service name, version, and time, for example `{"service": "participation", "version": "0.1.0", "time": "..."}`.
- The structure of a Go service (see "Structure of a service" below), the same in all four services.
- Mock tests that check the structure (see "Mock tests" below).
- Frontend page that calls `/api/v1/ping` on all four services and shows each response (green or red per service).
- A managed PostgreSQL service with three logical databases (`company_db`, `participation_db`, `impact_db`) and a managed MongoDB service with `challenge_db`, one database per service, all empty.
- Docker image for each service and for the frontend.
- Deployment to the cloud environment (AKS, with Helm and a basic GitHub Actions pipeline), so the page is reachable from the internet and shows all four services answering.

### Out of scope
- RabbitMQ. It is not set up in this stage.
- Everything else: authentication, companies, challenges, participation, donations, impact, events, business rules, database tables, seed data, OpenAPI beyond the ping and health endpoints.

## Structure of a service

Every Go service has the same structure. The code is split into directories by responsibility, so the logic, the HTTP side, and the database side are separate:

```
<service-repository>/
├── cmd/<service>/main.go      # starts the program, wiring only
└── internal/
    ├── config/                # reads the configuration from environment variables
    ├── domain/                # the logic of the service
    ├── http/                  # everything about HTTP connections
    └── store/                 # the database connection and, later, the queries
```

- `cmd/<service>/main.go` reads the configuration, builds the parts, and starts the HTTP server. It contains no logic.
- `internal/domain` is the logic. It knows nothing about HTTP or the database. In this stage it only builds the answer of the ping endpoint (service name, version, time).
- `internal/http` is the HTTP side: the router, the handlers, the middleware, and the health and ping endpoints. A handler only translates between HTTP and the logic. It holds no rules.
- `internal/store` is the database side. In this stage it only opens the connection and provides the check that `/health/ready` uses. It is used through an interface, so a test can replace it with a mock.
- `internal/config` reads the configuration variables from the plan and hands them to the other parts.
- Dependencies point one way: `http` uses `domain`, and `domain` uses neither `http` nor `store`.
- Directories for later stages (for example for RabbitMQ messaging and for database migrations) are added when they are needed, next to the ones above.

Adding an endpoint later means adding the logic to `domain` and a handler and a route to `http`. `main.go` and the other directories stay as they are.

## Mock tests

The tests in this stage are small and need no database, no RabbitMQ, and no network. They check that the structure works:

- A test of `domain` that checks the ping answer.
- A test of each `http` handler with a standard test HTTP server, checking the status code and the shape of the JSON.
- A test of `/health/ready` with a mock of the `store` check, once reporting the database as reachable and once as unreachable.

`go test ./...` runs all of them.

## Checklist

- [ ] The four service repositories and the `frontend` repository set up as described in `plan.md` 1.4
- [ ] Each service has the structure from "Structure of a service", with the logic, the HTTP side, and the database side in separate directories
- [ ] Mock tests exist for the logic, the handlers, and the readiness check, and `go test ./...` passes with no database or RabbitMQ running
- [ ] `go test ./...` runs in the GitHub Actions pipeline
- [ ] Each service responds on `/health/started`, `/health/ready`, `/health/live`, and `/api/v1/ping`
- [ ] `/health/ready` fails when the service's own database is unreachable
- [ ] Frontend page shows the ping result for all four services
- [ ] Docker images build for all services and the frontend
- [ ] Helm deploys the whole system into AKS
- [ ] GitHub Actions builds the images and deploys on merge to main
- [ ] The deployed page shows all four services answering from the cloud
