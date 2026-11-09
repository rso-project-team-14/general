# Stage 1: Basic demo

Back to [plan.md](../../plan.md).

## Goal

Show that the architecture works end to end on a laptop. Every service starts, talks to its own database, and one happy-path flow runs through RabbitMQ. Rules are minimal and hard-coded where needed. Auth is out of scope.

## Scope

### In scope
- Four Go services with `/healthz`, `/readyz`, and one or two real endpoints each.
- One PostgreSQL instance with four logical databases, created by `deploy/docker-compose.yml`.
- One RabbitMQ instance with the `butterfly.events` exchange declared at startup.
- Frontend with three screens: challenge list, complete a survey challenge, impact summary.
- One seeded company, one seeded user, one seeded charity organization, one seeded group challenge.
- `docker compose up` starts everything.

### Out of scope
- Authentication and authorization (a fixed demo user is used).
- Invite codes and company creation from the UI.
- Repeat-prevention, budget checks, and the transactional outbox (Stage 2).
- Kubernetes, Helm, and CI/CD (Stage 3).

## Minimal endpoints

| Service | Endpoint | Purpose |
|---|---|---|
| company-membership | `GET /api/v1/companies/{companyId}` | Returns the seeded company |
| challenge-campaign | `GET /api/v1/challenges` | Lists seeded challenges |
| participation | `POST /api/v1/participations` | Starts and completes a survey challenge in one call |
| donation-impact | `GET /api/v1/impact/me` | Returns the user's donation total and count |
| donation-impact | `GET /api/v1/impact/companies/{companyId}` | Returns aggregated totals only |

The full request and response shapes go into `api/*.yaml` during this stage, with a note that they are draft.

## Happy-path flow

1. The user submits the survey in the frontend. The request hits `participation`.
2. `participation` stores the completion and publishes `ChallengeCompleted` to RabbitMQ directly (no outbox yet).
3. `challenge-campaign` consumes it, and if the challenge is a group challenge and its goal is reached, publishes `DonationAuthorized`.
4. `donation-impact` consumes it and writes one ledger row.
5. The frontend refreshes the impact summary and shows the new total.

## Technical notes

- Go version and HTTP router: pick one and use it in all four services (for example `net/http` with `chi`).
- Migrations: one `migrations/001_init.sql` per service, applied on startup.
- Messaging library: `github.com/rabbitmq/amqp091-go`.
- Frontend: Vite + React + TypeScript, built to static files and served by nginx.
- Seed data lives in each service's migrations or in a `seed` command, never in the frontend.

## Checklist

- [ ] Repository layout from `plan.md` 1.4 created
- [ ] `deploy/docker-compose.yml` starts PostgreSQL, RabbitMQ, all four services, and the frontend
- [ ] Each service has `/healthz` and `/readyz`, and `/readyz` fails when its DB is down
- [ ] Draft OpenAPI files for the endpoints above exist in `api/`
- [ ] Seed data loaded for one company, one user, one charity, one group challenge
- [ ] Happy-path flow works from the UI with no manual steps after `docker compose up`
- [ ] Logs are JSON and include `X-Request-ID`
- [ ] Demo runbook added to this file (how to start, what to click)

## Open decisions this stage depends on

- Plan 1.12 item 4 (charity organizations): seeded only for this stage.
- Plan 1.12 item 5 (currency): EUR is assumed.
