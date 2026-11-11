# Stage 2: Database and API call

<!-- sha256: cf8a0769c597e7635810c5d2c3a75bf84a3f5a642de17c4d02391186ab52878f -->

Back to [plan.md](../../plan.md). Previous stage: [Stage 1](stage-1-demo.md). Next stage: [Stage 3](stage-3-cloud.md).

## Goal

Add what Stage 1 left out: connect the databases, and make an API call from a service. This stage is not the minimum viable product. It only adds the two kinds of connections to the working Kubernetes, frontend, and backend setup from Stage 1, and still has no business logic.

## Scope

### In scope
- Each service connects to its own database, managed PostgreSQL, or MongoDB for `challenge` (see `plan.md` 1.10 for how the connection details reach the services), through a real `internal/store`. The databases stay empty: one database per service, no business tables.
- `GET /health/ready` now also checks that the service's own database is reachable, and fails when it is not.
- An API call from a service to another service, or to an external API, through a real `internal/client`. Which call is made is still to be decided.
- The structure from `plan.md` section 1.4 is now complete, with the `store`, `client`, and `migrations` directories added next to the ones from Stage 1. The step that applies migrations at startup is in place, but there are no business tables yet, so there is nothing for it to create.
- The database and the client are mocked in the tests (see "Tests" below).

### Out of scope
- RabbitMQ and events.
- Business logic, authentication, and everything else not named above.

## Tests

In every test the `store` and the `client` are replaced by mocks that implement the interfaces defined by `domain`. A test never uses a real database or makes a real outgoing call. `make test` runs all of them with no database and no network.

- A test of `/health/ready` with a mock `store` check, once reporting the database as reachable and once as unreachable.
- A test of the logic that makes the API call, with a mock `client`.

## Checklist

- [ ] Each service connects to its own database through `internal/store`
- [ ] `/health/ready` fails when the service's own database is unreachable
- [ ] The API call works in the cloud through `internal/client`
- [ ] The `store`, `client`, and `migrations` directories follow the structure in `plan.md` section 1.4, and migrations are applied at startup
- [ ] Tests exist for the readiness check and for the call, with the database and the client mocked, and `make test` passes with no database or network
- [ ] Everything runs in AKS as in Stage 1, now with the databases and the call
