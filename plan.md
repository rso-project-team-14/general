# Butterfly Give: Project Plan

This plan is a living document. Infrastructure is shared by every microservice. Service internals and delivery stages are at the end.

---

## Part 1: Shared infrastructure

### 1.1 Product summary

Butterfly Give is a cloud-native prototype that connects companies, their employees, and charity organizations. A company creates a charity challenge (for example, a short survey) with a goal and a budget. Employees complete challenges in the web UI. Successful completions advance the shared progress and can trigger a donation to a selected organization. Users see their own challenges and impact. Companies see aggregated results only, never the names of individual employees.

### 1.2 Technology stack

| Area | Choice |
|---|---|
| Frontend | React + TypeScript, responsive SPA, served by nginx |
| Backend | Go, REST APIs, one binary per microservice |
| Data | Database-per-service (one logical DB per service). PostgreSQL for `company-membership`, `participation`, and `donation-impact`. MongoDB for `challenge`, because challenges have varied, unpredictable shapes that suit a document model better than fixed tables |
| Async messaging | RabbitMQ for business events |
| Containers | Docker images per service and for the frontend |
| Orchestration | Kubernetes on Azure Kubernetes Service (AKS) |
| Deployment | Helm charts |
| CI/CD | GitHub Actions: build, test, image push, Helm deploy |
| API contracts | OpenAPI 3 files, one per service, kept in the repo |

### 1.3 Services at a glance

| Service | Short name | Owns database | Responsibility |
|---|---|---|---|
| Company & Membership | `company-membership` | `company_db` | Companies, memberships, invite codes, user roles within a company |
| Challenge | `challenge` | `challenge_db` (MongoDB) | Challenge templates and challenges, business rules (validity, goal, budget, amount per success), group progress, donation trigger decision |
| Participation | `participation` | `participation_db` | Starting and completing challenges, survey answers, validity checks, repeat-prevention |
| Donation & Impact | `donation-impact` | `impact_db` | Charity organizations, donation ledger, personal and aggregated impact |

The frontend is a separate deployable. It has no database.

Communication rules:
- Synchronous calls: REST over HTTPS, JSON, through the frontend's nginx reverse proxy or the Kubernetes ingress.
- Asynchronous calls: RabbitMQ events, see section 1.7.
- A service never reads or writes another service's database.
- A service that needs data from another service calls its REST API or subscribes to events.

### 1.4 Repository layout (monorepo)

```
general/
├── plan.md                         # this file
├── docs/
│   └── stages/                     # one document per delivery stage
│       ├── stage-1-demo.md
│       ├── stage-2-mvp.md
│       └── stage-3-cloud.md
├── api/                            # OpenAPI contracts, one file per service
│   ├── company-membership.yaml
│   ├── challenge.yaml
│   ├── participation.yaml
│   └── donation-impact.yaml
├── services/                       # Go microservices
│   ├── company-membership/
│   ├── challenge/
│   ├── participation/
│   └── donation-impact/
├── frontend/                       # React + TypeScript SPA
├── deploy/
│   ├── docker-compose.yml          # local development stack
│   └── helm/                       # Helm charts (umbrella chart + per-service values)
└── .github/workflows/              # CI/CD pipelines
```

Each Go service follows the same internal layout (`cmd/`, `internal/http`, `internal/domain`, `internal/store`, `internal/messaging`, `migrations/` for the PostgreSQL services; `challenge` keeps its index and validation setup in the same place). The same layout keeps the services easy to review and to compare.

### 1.5 Local development environment

- `deploy/docker-compose.yml` starts: one PostgreSQL container that hosts the three relational logical databases (`company_db`, `participation_db`, `impact_db`), one MongoDB container for `challenge_db`, one RabbitMQ container with management UI, the four services, and the frontend.
- Each PostgreSQL service creates its own database role and schema at startup through its own migrations. `challenge` creates its own MongoDB user, collections, and indexes at startup.
- MongoDB runs as a single-node replica set locally, because multi-document transactions (needed for the outbox and idempotency, see 1.7) require a replica set.
- Every service reads its configuration from environment variables only. No config files with secrets are committed.

### 1.6 Runtime conventions (apply to every service)

- **Ports:** HTTP on 8080 inside the container. Ports are set through the Kubernetes Service, not hard-coded elsewhere.
- **Base path:** REST endpoints live under `/api/v1/...`.
- **Health:** `GET /healthz` (process alive) and `GET /readyz` (DB and RabbitMQ reachable).
- **Configuration variables (per service):** `PORT`, `DATABASE_URL`, `RABBITMQ_URL`, `LOG_LEVEL`, `SERVICE_NAME`. `DATABASE_URL` is a PostgreSQL connection string, except in `challenge`, where it is a MongoDB connection string.
- **Logging:** structured JSON logs to stdout. Each request has an `X-Request-ID` header. It is generated at the edge if missing, returned in responses, and included in every log line.
- **Errors:** RFC 7807 `application/problem+json` for all 4xx and 5xx responses.
- **Timestamps:** UTC, ISO 8601 with `Z`.
- **IDs:** UUID v4 for all entities.
- **Graceful shutdown:** on SIGTERM the service stops accepting requests, finishes in-flight work, closes its RabbitMQ consumer, then exits.

### 1.7 Messaging contract

- **Broker:** RabbitMQ.
- **Exchange:** one topic exchange `butterfly.events`, durable.
- **Routing keys:** `challenge.completed` and `donation.authorized`.
- **Delivery:** at-least-once. Every consumer must be idempotent.
- **Queues:** one durable queue per consuming service, bound to the routing keys it needs. For example, `challenge.challenge-completed`.
- **Failures:** each queue has a dead-letter exchange `butterfly.events.dlx`. Messages that fail after 3 retries go there and are logged.
- **Idempotency:** every consumer keeps a `processed_events(event_id PRIMARY KEY, processed_at)` table in its own database (a `processed_events` collection with `event_id` as `_id` in `challenge_db`). The event is applied and recorded in the same transaction.

Event envelope (JSON, every event):

```json
{
  "eventId": "uuid-v4",
  "type": "ChallengeCompleted",
  "version": 1,
  "occurredAt": "2026-11-09T12:00:00Z",
  "producer": "participation",
  "payload": { }
}
```

Event catalog (from the project brief):

| Event | Producer | Consumers | Payload (summary) |
|---|---|---|---|
| `ChallengeCompleted` | participation | challenge | `participationId`, `challengeId`, `companyId`, `userId`, `completedAt`, `answersValid` |
| `DonationAuthorized` | challenge | donation-impact | `donationId`, `challengeId`, `companyId`, `organizationId`, `amount`, `currency`, `sourceChallengeIds` |

Payloads are versioned through the `version` field. A breaking change means a new version number, and the old version stays supported until all consumers have moved on.

### 1.8 Data ownership and schema rules

- One logical database per service. The three PostgreSQL databases live in the same PostgreSQL instance locally and in AKS. `challenge_db` lives in a separate MongoDB instance. Each service has its own credentials with access to its own database only.
- PostgreSQL schema changes go through versioned migration files in each service's `migrations/` folder, applied at startup.
- MongoDB (`challenge_db`) has no fixed table schema, so the flexible challenge shape is allowed. Fields every challenge must have (type, validity period, goal, budget, amount per success) are enforced by a MongoDB JSON Schema validator on the `challenges` collection. Challenge-specific content (for example survey questions) can vary per challenge. Indexes are created at startup.
- No foreign keys across databases. A reference to another service's entity is a plain UUID.
- Monetary amounts are stored as integers in cents, with an ISO 4217 currency code.

### 1.9 Security and privacy

- Authentication and authorization model: **open decision**, see 1.12.
- Aggregated company views must never expose individual employee names or IDs. The Donation & Impact service enforces this in its read API. Company views contain counts and sums only.
- Invite codes are random, single-company, expire, and have a use limit.
- Secrets (database passwords, RabbitMQ credentials) live in Kubernetes Secrets, not in Helm values or the repo.
- The frontend and backend only talk over HTTPS in AKS. TLS terminates at the ingress.

### 1.10 Kubernetes and Helm layout

- One Deployment and one Service per microservice and one for the frontend.
- One Helm chart per service, plus an umbrella chart that deploys all of them together.
- Resources per container: small requests and limits, enough to fit a student-sized AKS node pool.
- Readiness and liveness probes use `/readyz` and `/healthz`.
- Configuration in ConfigMaps, credentials in Secrets, both referenced from the Deployment. The image itself carries no environment-specific values.
- An Ingress routes `/` to the frontend and `/api/` to the services, with path-based routing to each service.
- PostgreSQL, MongoDB, and RabbitMQ: **open decision**, see 1.12. Options are Helm-deployed in-cluster or managed services.

### 1.11 CI/CD

GitHub Actions builds, tests, and deploys the system. Deployments target two **GitHub Environments**, `staging` and `production`. Each environment holds its own secrets, variables, and optional protection rules (such as required reviewers), so the same workflow deploys to either one. See 1.13 for the branching model.

GitHub Actions workflows:
1. **On pull request:** lint, unit tests, OpenAPI validation, Docker build (no push).
2. **On merge to main:** build and tag images, push to the container registry, and deploy to the `staging` environment with `helm upgrade --install`.
3. **Promotion to production:** the same image tags that passed in `staging` are deployed to the `production` environment. The `production` environment can require an approval before the job runs.
4. **Manual:** deploy a chosen image tag to a chosen environment (`staging` or `production`).

Container registry: **open decision**, see 1.12. Default assumption: Azure Container Registry.

### 1.12 Open decisions

These need an answer from the team or the course staff. Each stage document lists the decisions it depends on.

1. **Authentication:** Options are (a) a simple login in the Company & Membership service with JWT issued by that service, (b) an external identity provider such as Microsoft Entra ID. Not needed for Stage 1.
2. **Data services in AKS:** in-cluster PostgreSQL, MongoDB, and RabbitMQ through Helm, or Azure Database for PostgreSQL, a managed MongoDB-compatible service (for example Azure Cosmos DB for MongoDB), and a RabbitMQ container. Needed for Stage 1.
3. **Infrastructure as code:** plain Azure CLI scripts, or Terraform / Bicep for the AKS cluster. Needed for Stage 1.
4. **Charity organizations:** seeded data only, or an admin endpoint to add them. Not needed for Stage 1.
5. **Currency:** single currency (EUR) or multiple. Default assumption: EUR only.
6. **Frontend language:** Slovenian, English, or both. Default assumption: English UI with Slovenian project docs.

### 1.13 Git workflow and environments

Source: issue [#8](https://github.com/rso-project-team-14/general/issues/8) (branching strategy research), part of the broader git-practices issue [#5](https://github.com/rso-project-team-14/general/issues/5).

**Branching model: GitHub Flow.**
- `main` is the only long-lived branch and is always deployable.
- All work happens on short-lived branches created from `main` and merged back through a pull request.
- A long-living `dev` branch is deliberately **not** used: long-living branches drift away from production code.

**Staging through GitHub Environments, not branches.**
- Two environments exist: `staging` and `production`. `staging` lets the microservices be tested together in a realistic setting before release.
- Both are implemented with GitHub Environments (for environment-scoped secrets, variables, and optional approvals), not with separate branches.
- Changes merged to `main` deploy to `staging` first. Promotion to `production` is a separate workflow step, see 1.11.

**Feature flags are not used.**
- Deployment and release do not need to be decoupled in this project, and flags would make the code harder to read.
- Unfinished work stays on its branch until it is ready to merge, so branches must stay small and short-lived.

**Still to be agreed in issue #5** (the issue only settled the model above):
- Branch naming convention.
- Pull request and review rules (required approvals, required checks, merge method).
- Commit format. Conventional Commits is already assumed in #5.
- Whether promotion from `staging` to `production` needs a manual approval (required reviewers) or is automatic.

---

## Part 2: Microservice internals and delivery stages

### 2.1 Internal logic of each service (summary)

Detailed behavior, endpoints, and data models are defined in the stage documents. This section states the core responsibilities that stay the same across stages.

**Company & Membership (`company-membership`)**
- Creates companies and assigns a company admin (`representative`).
- Generates invite codes and lets a user join a company with a code.
- Stores membership and role (`employee` or `representative`).
- Answers "who is this user's company" for other services through REST. Other services never query `company_db`.

**Challenge (`challenge`)**
- Representatives create challenges with type (`personal` or `group`), validity period, goal, budget, and amount per successful completion.
- Publishes a challenge to the employees of its company.
- Consumes `ChallengeCompleted`, updates group progress, and checks the challenge's donation rule and remaining budget.
- When the conditions for a donation are met, publishes `DonationAuthorized` and decreases the remaining budget in the same transaction as the outbox record.

**Participation (`participation`)**
- Starts a challenge for a user, records answers to the survey, and checks the completion rules.
- Enforces repeat-prevention: a user cannot complete the same challenge twice inside its window.
- Publishes `ChallengeCompleted` on success, using a transactional outbox so the event is never lost after the DB commit.

**Donation & Impact (`donation-impact`)**
- Stores charity organizations (seeded or managed through an admin endpoint, to be decided).
- Consumes `DonationAuthorized` idempotently and writes a donation ledger entry.
- Computes personal impact (per user) and aggregated impact (per company and per challenge, no names).

**Frontend (`frontend`)**
- Login and company join flow.
- Challenge list with filters (personal, group, open, completed).
- Survey view and completion.
- Impact dashboards for the user and for the company representative.
- Challenge creation form for the representative.

### 2.2 Cross-service flow (the complex use case from the brief)

1. The user completes a group challenge in the frontend. The request goes to `participation`.
2. `participation` validates the submission, records completion, writes a `ChallengeCompleted` event to its outbox, and publishes it.
3. `challenge` consumes the event, updates group progress, checks the challenge's donation rule and the remaining budget, and emits `DonationAuthorized` if the conditions are met.
4. `donation-impact` consumes `DonationAuthorized` idempotently, creates the ledger entry, and updates the impact view.
5. The frontend fetches updated progress and impact from the REST APIs.

Note on the transactional outbox: each service that publishes events writes them into an `outbox` table (an `outbox` collection in `challenge_db`) in the same transaction as the business change. A small publisher loop reads the outbox and publishes to RabbitMQ. This is how "DB write succeeded but event lost" is avoided. It is not part of Stage 1.

### 2.3 Delivery stages

| Stage | Document | Goal |
|---|---|---|
| 1 | [docs/stages/stage-1-demo.md](docs/stages/stage-1-demo.md) | Basic demo: no business logic, the services only answer basic API requests and run in the cloud environment |
| 2 | [docs/stages/stage-2-mvp.md](docs/stages/stage-2-mvp.md) | Minimum viable product (to be planned) |
| 3 | [docs/stages/stage-3-cloud.md](docs/stages/stage-3-cloud.md) | To be planned |

Stages 2 and 3 are empty placeholders. They will be planned after Stage 1 is done.

### 2.4 Definition of done (applies to every stage)

- Code merged to the main branch through a reviewed pull request.
- Unit tests for domain rules, integration tests for each service's REST API and DB layer.
- OpenAPI contract matches the implementation.
- The stage document's checklist is fully ticked, or open items are moved to the next stage with a note.
- `plan.md` is updated if an infrastructure decision changed.
