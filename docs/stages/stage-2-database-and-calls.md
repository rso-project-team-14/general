# Stage 2: Database and API call

<!-- sha256: 69f864131ed363a6b4fd90d9b11c9825daa6a3fe1740e49ad0f751c16e57afa0 -->

Back to [plan.md](../../plan.md). Previous stage: [Stage 1](stage-1-demo.md). Next stage: [Stage 3](stage-3-cloud.md).

## Goal

Add what Stage 1 left out: connect the databases, and make an API call from a service. This stage is not the minimum viable product. It only adds the two kinds of connections to the working Kubernetes, frontend, and backend setup from Stage 1, and still has no business logic.

## Who does what

The same split as in Stage 1:

- **Agents** implement only the code: `internal/store`, `internal/client`, the readiness check, the API call, and the tests.
- **The team** sets up and manages the real databases (the managed PostgreSQL and MongoDB) and does all the deployment itself, to learn it. An agent working on this stage does not create or change databases, cloud resources, Dockerfiles, Helm charts, pipeline files, or cluster configuration.

## Scope

### In scope
- Each service connects to its own database, managed PostgreSQL, or MongoDB for `challenge` (see `plan.md` 1.10 for how the connection details reach the services), through a real `internal/store`. The databases stay empty: one database per service, no business tables.
- `GET /health/ready` now also checks that the service's own database is reachable, and fails when it is not.
- An API call from a service to another service, or to an external API, through a real `internal/client`. Which call is made is still to be decided.
- The structure from `plan.md` section 1.4 is now complete, with the `store` and `client` directories added next to the ones from Stage 1.
- Tests that use the real database and the real client, with no mocks (see "Tests" below).

### Out of scope
- RabbitMQ and events.
- Business logic, authentication, and everything else not named above.

## Tests

Nothing is mocked in this stage. The tests use the real `store` against a real database and the real `client` to make a real call. This means `make test` needs the database and the called service to be reachable, with their addresses given through the configuration variables.

- A test of `/health/ready` against the real database, which succeeds when the database is reachable, and which fails when the service is pointed at an address where there is no database.
- A test of the logic that makes the API call, with the real `client` and a real call.

## Checklist

Implementation (agents):

- [ ] Each service connects to its own database through `internal/store`
- [ ] `/health/ready` fails when the service's own database is unreachable
- [ ] The API call is made through `internal/client`
- [ ] The `store` and `client` directories follow the structure in `plan.md` section 1.4
- [ ] Tests exist for the readiness check and for the call, use the real database and the real client with no mocks, and `make test` passes when they are reachable

Databases and deployment (the team):

- [ ] The managed databases are set up and reachable from the cluster and from where the tests run
- [ ] Everything runs in AKS as in Stage 1, now with the databases and the call, and the API call works in the cloud
