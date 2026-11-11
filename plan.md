# Butterfly Give: Project Plan

<!-- sha256: 338d9ec6e39ecd6d021b934e99294cc305c33e84044c20f6c68bcd64cd552e18 -->

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
| API contracts | Planned contracts are documents in `general` (`api/`). Once a service is implemented, its OpenAPI 3 spec lives in the service repository and is the truth |

### 1.3 Services at a glance

| Service | Short name | Owns database | Responsibility |
|---|---|---|---|
| Company & Membership | `company-membership` | `company_db` | Companies, memberships, invite codes, user roles within a company |
| Challenge | `challenge` | `challenge_db` (MongoDB) | Challenge templates and challenges, questions, business rules (validity, goal, budget, amount per success), group progress, donation trigger decision. Publishes challenges to other services as events and through a bootstrap endpoint |
| Participation | `participation` | `participation_db` | Starting and completing challenges, survey answers, **validation of submissions** against its own read-only copy of the challenges, repeat-prevention |
| Donation & Impact | `donation-impact` | `impact_db` | Charity organizations, donation ledger, personal and aggregated impact |

The frontend is a separate deployable in its own repository. It has no database.

Communication rules:
- Synchronous calls: REST over HTTPS, JSON, through the gateway (Kubernetes Gateway API with Envoy, see 1.10).
- Asynchronous calls: RabbitMQ events, see section 1.7.
- A service never reads or writes another service's database.
- A service that needs data from another service calls its REST API or subscribes to events.
- `participation` does not call `challenge` while users complete challenges. It keeps its own read-only copy of the challenges, built from `ChallengePublished` events. The only synchronous call is the bootstrap at startup (see 2.1, "Responsibility split").

### 1.4 Repositories

There is no monorepo. Every microservice has its own repository, the frontend has its own repository, and `general` holds documentation only.

| Repository | Content |
|---|---|
| `general` | Documentation: plan, stage documents, planned API contracts, changelog, project-wide issues. No implementation code (see `CLAUDE.md`) |
| `company-service` | `company-membership` service |
| `challenge-service` | `challenge` service |
| `participation-service` | `participation` service |
| `impact-service` | `donation-impact` service |
| `frontend` | React + TypeScript frontend (repository to be created) |

Where the deployment files (Helm charts, local docker-compose stack) live is an open decision, see 1.12 item 13.

**Source of truth for API contracts**
- Before implementation, the planned contract lives in `general` (`api/`). It is a contract document, not an OpenAPI spec.
- After implementation, the truth lives in the service repository: its code and its OpenAPI spec. The contract in `general` is the plan the service was built from.

Layout of `general`:

```
general/
├── CLAUDE.md                       # rules for working in this repo
├── changelog/                      # one file per change, read by the other repos
├── scripts/
│   └── doc-hash.sh                 # recalculates and checks the content hash on line 3 of every document
├── plan.md                         # this file
├── docs/
│   └── stages/                     # one document per delivery stage
│       ├── stage-1-demo.md
│       ├── stage-2-mvp.md
│       └── stage-3-cloud.md
└── api/                            # planned API contracts, one document per service
    ├── company-membership.md
    ├── challenge.md
    ├── participation.md
    └── donation-impact.md
```

Each Go service follows the same internal layout in its own repository (`cmd/`, `internal/http`, `internal/domain`, `internal/store`, `internal/messaging`, `migrations/` for the PostgreSQL services; `challenge` keeps its index and validation setup in the same place). The same layout keeps the services easy to review and to compare. The frontend is not a Go project and has its own layout.

### 1.5 Local development environment

TBD

### 1.6 Runtime conventions (apply to every service)

- **Ports:** HTTP on 8080 inside the container. Ports are set through the Kubernetes Service, not hard-coded elsewhere.
- **Base path:** REST endpoints live under `/api/v1/...`.
- **Health:** three endpoints, one for each Kubernetes probe type.
  - `GET /health/started`: the service finished starting (configuration loaded, migrations applied, connections made, and for `participation` the challenge bootstrap complete). Until it succeeds, Kubernetes does not run the other two probes.
  - `GET /health/ready`: the service can handle requests now (its database and RabbitMQ are reachable). If it fails, the pod gets no traffic but is not restarted.
  - `GET /health/live`: the process is alive and not stuck. It checks no dependencies. If it fails, the container is restarted.
- **Configuration variables (per service):** `PORT`, `DATABASE_URL`, `RABBITMQ_URL`, `LOG_LEVEL`, `SERVICE_NAME`. `DATABASE_URL` is a PostgreSQL connection string, except in `challenge`, where it is a MongoDB connection string.
- **Logging:** structured JSON logs to stdout. Each request has an `X-Request-ID` header. It is generated at the edge if missing, returned in responses, and included in every log line.
- **Errors:** RFC 7807 `application/problem+json` for all 4xx and 5xx responses.
- **Timestamps:** UTC, ISO 8601 with `Z`.
- **IDs:** UUID v4 for all entities.
- **Graceful shutdown:** on SIGTERM the service stops accepting requests, finishes in-flight work, closes its RabbitMQ consumer, then exits.

### 1.7 Messaging contract

> **Not finished.** This plan for the RabbitMQ events is a first draft and will surely be reworked. Treat the exchange, routing keys, event names, payloads, and delivery rules below as provisional.

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
| `ChallengePublished` | challenge | participation | `challengeId`, `companyId`, `version`, `type`, `validFrom`, `validUntil`, `questions`, and the other fields `participation` needs to validate a submission, as fixed by the contract in `api/`. Not the budget, goal, or progress |
| `ChallengeCompleted` | participation | challenge | `participationId`, `challengeId`, `companyId`, `userId`, `completedAt` |
| `DonationAuthorized` | challenge | donation-impact | `donationId`, `challengeId`, `companyId`, `organizationId`, `amount`, `currency`, `sourceChallengeIds` |

`ChallengePublished` is emitted when `challenge` receives a new challenge. The payload carries exactly the data `participation` needs at that `version`, as fixed by the contract, not the whole challenge. Which other changes emit events (edit, close, withdraw) is an open decision, see 1.12 item 12.

`ChallengeCompleted` is only published after the submission passed validation in `participation`, so the payload carries no validity flag. Whether payloads carry `userId` is an open decision, see 1.12 item 9.

Payloads are versioned through the `version` field. A breaking change means a new version number, and the old version stays supported until all consumers have moved on.

### 1.8 Data ownership and schema rules

- One logical database per service. The three PostgreSQL databases live in the same PostgreSQL instance locally and in AKS. `challenge_db` lives in a separate MongoDB instance. Each service has its own credentials with access to its own database only.
- PostgreSQL schema changes go through versioned migration files in each service's `migrations/` folder, applied at startup.
- MongoDB (`challenge_db`) has no fixed table schema, so the flexible challenge shape is allowed. Fields every challenge must have (type, validity period, goal, budget, amount per success) are enforced by a MongoDB JSON Schema validator on the `challenges` collection. Challenge-specific content (for example survey questions) can vary per challenge. Indexes are created at startup.
- **No coupling between databases.** Services share no tables and no schema, and how `challenge` stores a challenge internally is private to it. What one service sends to another is defined by a **fixed contract** in `api/` (endpoint shapes and event payloads). A consumer receives only the data it needs and keeps it in its own tables, shaped for its own use.
- No foreign keys across databases. A reference to another service's entity is a plain UUID.
- A service may keep a **read-only copy** of another service's data, built from events and a bootstrap endpoint of the owner. The copy is never written by anything except the event and bootstrap handling, and the owner stays the only source of truth. The one such copy for now is the challenges in `participation_db`. It holds only the fields named in the `ChallengePublished` contract, in normal columns of `participation_db` (PostgreSQL), with no JSONB or free-form data, because the contract is fixed.
- Monetary amounts are stored as integers in cents, with an ISO 4217 currency code.

### 1.9 Security and privacy

- Authentication and authorization model: **open decision**, see 1.12.
- Aggregated company views must never expose individual employee names or IDs. The Donation & Impact service enforces this in its read API. Company views contain counts and sums only.
- Invite codes are random, single-company, expire, and have a use limit.
- Secrets (database passwords, RabbitMQ credentials) live in Kubernetes Secrets, not in Helm values or the repo.
- The frontend and backend only talk over HTTPS in AKS. TLS terminates at the gateway.

### 1.10 Kubernetes and Helm layout

- One Deployment and one Service per microservice and one for the frontend.
- One Helm chart per service, plus an umbrella chart that deploys all of them together.
- Resources per container: small requests and limits, enough to fit a student-sized AKS node pool.
- Startup, readiness, and liveness probes use `/health/started`, `/health/ready`, and `/health/live`.
- Configuration in ConfigMaps, credentials in Secrets, both referenced from the Deployment. The image itself carries no environment-specific values.
- **Gateway API with Envoy, not an Ingress.** The nginx Ingress controller is not used, because it is no longer supported. The cluster entry point is a Kubernetes Gateway API `Gateway`, with Envoy as the implementation behind it. `HTTPRoute` resources route `/` to the frontend and `/api/` to the services, with path-based routing to each service. The frontend container still serves its static files with its own nginx, which is unrelated to the Ingress controller.
- **PostgreSQL and MongoDB are managed services**, not run inside the cluster. The Helm charts therefore deploy no database. Each service gets its connection string and credentials from a Kubernetes Secret. Which managed products are used is still to be chosen.
- **RabbitMQ hosting is an open decision**, see 1.12 item 2.

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
2. **RabbitMQ hosting:** run it inside the cluster (installed with Helm or an operator), or use a managed RabbitMQ service from a third party. This is still to be decided. PostgreSQL and MongoDB are already decided as managed services (see 1.10), but which managed products to use is also still to be chosen. Needed for Stage 1.
3. **Infrastructure as code:** plain Azure CLI scripts, or Terraform / Bicep for the AKS cluster. Needed for Stage 1.
4. **Charity organizations:** seeded data only, or an admin endpoint to add them. Not needed for Stage 1.
5. **Currency:** single currency (EUR) or multiple. Default assumption: EUR only.
6. **Frontend language:** Slovenian, English, or both. Default assumption: English UI with Slovenian project docs.
7. **Donation timing:** does a donation fire on every successful completion (capped by the remaining budget, using the amount per success), or once when the group goal is reached? This decides the core logic of the `challenge` service.
8. **Personal challenges:** do they use the same flow as group challenges? If yes, is the goal of a personal challenge just one completion by that user, and does it also trigger a donation?
9. **User identity in events:** should `DonationAuthorized` (and `ChallengeCompleted`) carry `userId`, so `donation-impact` can attribute personal impact, with anonymity enforced only in its company-facing read API? Or should events carry no user data, which makes personal impact harder to compute?
10. **Stale copy in `participation`:** the copy of the challenges is eventually consistent. How long a gap is acceptable between a challenge being created or closed in `challenge` and `participation` knowing about it? Is a periodic re-sync from the snapshot endpoint needed as a safety net, or is the bootstrap at startup enough?
11. **Shape of the contract and new challenge types:** the `ChallengePublished` contract is fixed, and `participation` stores it in normal columns. Challenges can still differ in content (survey questions now, other types later). How are the questions and validation rules expressed as fixed fields? And how is a new challenge type added later, for example as a new contract version that `participation` handles next to the old one? Survey is the only type for now.
12. **Replication details (proposed defaults in brackets):** event granularity [one `ChallengePublished` event with the contract fields per new version]. Events for edit, close, and withdraw [not decided; a withdrawn or closed challenge needs some event, otherwise `participation` keeps accepting it]. Order and duplicates [apply only if the version is higher]. Snapshot endpoint shape [paginated, latest version of every challenge, optional filter by company]. Startup [`participation` not started until the bootstrap is complete].
13. **Where do the deployment files live?** The umbrella Helm chart and the local docker-compose stack need a home: a new `deploy` repository, or each service repository with its own chart plus one repository for the umbrella chart. They do not go into `general`, which is documentation only.

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

### 1.14 CLAUDE.md in every repository

Every service repository and the frontend repository has its own `CLAUDE.md`, created when the repository is initialized (for example with `/init`, then completed from this list). Keep it short and specific to that repository. Link to this plan instead of copying its content, so the two cannot drift apart. The standard sections below are the one exception: they are copied as they are.

**Standard sections (the start of every `CLAUDE.md`)**

These four sections are the same in every repository, except for the Stack section, which is filled in per repository. Copy them as written.

````markdown
## How to work in this repo

- Plan before editing: outline the approach and surface tradeoffs first. Do not hide confusion behind a confident edit.
- Simplicity first: smallest change that works, no premature abstraction (YAGNI).
- Surgical changes only: touch only what the task names; don't refactor unrelated code.
- State the goal and the definition of done up front; loop until verified against it.
- Ask when the spec is ambiguous; do not guess and ship the guess as fact.
- Stay in scope: no drive-by edits to neighboring code just because you're in the file.
- Tests are truth: run tests and they must pass before you claim done.
- Be concise: short answers, no recap of work you just did unless asked.

## Stack

- Go, REST/JSON API, RabbitMQ for events, packaged as a Docker image and deployed with Helm to Kubernetes (AKS). The shared stack is described in `plan.md` section 1.2 in the `general` repository.
- Database: <fill in: PostgreSQL or MongoDB>, owned by this service only.
- Prefer the repo's existing libraries over reaching for a new dependency.
- Don't infer the build tooling or the module layout. Read the repo.

## What burned us before

<!-- Guide for the agent: nothing is recorded yet. Do not add anything here on your own and do not invent incidents.
     When the user tells you to add an entry, write one short line: what went wrong, and the check that would have caught it.
     Example of the shape (not a real incident): "A job reported success while some records were skipped. Verify counts after bulk operations." -->

## Keep this file honest

- When you get corrected, add the lesson to this file (update CLAUDE.md) so the next session starts ahead.
````

In the frontend repository, replace the Stack section with: React and TypeScript web UI served by nginx, calling the services through the gateway under `/api/`. The package manager is not decided, so the agent must not infer one and must read the repo.

After the standard sections, add the project-specific items below.

A service's `CLAUDE.md` should contain:

1. **Purpose and place.** The repository name, which service it is (short name from 1.3), a short paragraph on its responsibility with a link to its part of section 2.1, and what it explicitly does not do.
2. **Link to `general`.** The repository `rso-project-team-14/general` is where the plan lives. `plan.md` is the source of truth for infrastructure, responsibilities, and stages, and the planned API contracts are in `api/`.
3. **Sync with `general` (required).** The changelog rule below, together with the "Last checked general changelog entry" line.
4. **Contracts.** Which contract documents in `general/api/` apply: the service's own and those of the services it talks to. Until the service is implemented, the planned contract is the guide. After that, the service's own OpenAPI spec and code are the truth, and any difference from the planned contract is reported through a change in `general`.
5. **Conventions.** The language version, the internal layout of the repository, and a pointer to the runtime conventions in 1.6 (port, health endpoints, configuration variables, JSON logging, `X-Request-ID`, error format, UUID v4, UTC timestamps). List only the deviations or additions specific to this service.
6. **Data.** Which database it owns and where its migrations live. It never reads or writes another service's database. Money is stored in cents. If the service keeps a read-only copy of another service's data (`participation` and the challenges), the rules from 1.8 for it.
7. **Events.** Which events the service produces and consumes (see 1.7, which is provisional), and the outbox and idempotency requirements that apply to it.
8. **Commands.** How to build, test, lint, run, and apply migrations. Marked TBD until local development (1.5) is decided.
9. **Git and pull requests.** GitHub Flow as in 1.13: short-lived branches from `main`, merged through pull requests. Commit format is pending in issue #5.
10. **Rules for Claude.**
    - Stay within this service's responsibility.
    - Do not resolve an open decision from 1.12 silently. Raise it as an issue or a change in `general`.
    - Do not change another service's code or database.
    - If the plan looks wrong or contradicts the code, say so instead of quietly diverging from it.
    - Never commit secrets.

The frontend's `CLAUDE.md` uses items 1 to 4, 8, 9, and 10. Instead of 5 to 7 it describes the frontend stack, which services' endpoints it calls through the gateway under `/api/`, and where the contracts for those calls are.

Suggested text for the sync rule (item 3):

> Before implementing a feature, list the `changelog/` directory in the `general` repository (`rso-project-team-14/general`) and compare the newest file name with the one recorded below under "Last checked general changelog entry".
> - If there are files newer than that one (file names start with a UTC timestamp, so alphabetical order is chronological), read them, then re-read the parts of `plan.md`, `docs/`, and `api/` they affect. Apply any changes that concern this repository, then update the "Last checked" line to the newest file name.
> - If there are no newer files, do not re-read `plan.md`.
> - Every document in `general` has its content hash on line 3 (`<!-- sha256: ... -->`, covering line 4 to the end). To check whether a specific document changed since you last read it, compare that line with the hash you recorded before reading the whole file.
>
> Last checked general changelog entry: _none yet_

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
- Representatives create challenges with type (`personal` or `group`), questions, validity period, goal, budget, and amount per successful completion.
- Publishes a challenge to the employees of its company. A published challenge is versioned, so a change never affects a submission already in progress.
- When it receives a new challenge, it emits `ChallengePublished` with the fields defined in the contract, written through the transactional outbox in the same transaction as the challenge.
- Provides a bootstrap endpoint such as `GET /api/v1/challenges/snapshot` that returns the current state (latest version) of all challenges, paginated. It is for service-to-service use and is not routed through the public gateway. A service that lost its copy, for example after a reboot or when started for the first time, rebuilds it from this endpoint.
- Serves the challenge and its questions to the frontend directly.
- Does not validate submissions.
- Consumes `ChallengeCompleted`, updates group progress, and checks the challenge's donation rule and remaining budget.
- When the conditions for a donation are met, publishes `DonationAuthorized` and decreases the remaining budget in the same transaction as the outbox record.

**Participation (`participation`)**
- Keeps a **read-only copy of the challenges** in `participation_db`, built from `ChallengePublished` events. It applies an event only if its `version` is higher than the stored one, so duplicates and old events are harmless.
- Bootstraps the copy at startup: it subscribes to the events first, then loads everything from the `challenge` snapshot endpoint, applying the same version rule. This way a reboot or a first start cannot leave gaps. It should report not started (`/health/started`) until the bootstrap is complete.
- Starts a challenge for a user and records the answers.
- Validates every submission itself, against its copy: the validity window, the challenge status, and the answers against the questions. A challenge it does not know is rejected with a clear error.
- Enforces repeat-prevention: a user cannot complete the same challenge twice inside its window.
- On a valid submission, records the completion and publishes `ChallengeCompleted` using a transactional outbox, so the event is never lost after the DB commit.
- Keeps working when `challenge` is down. Only new challenges are missed until it is back.
- Serves the user's history of completed challenges.

**Donation & Impact (`donation-impact`)**
- Stores charity organizations (seeded or managed through an admin endpoint, to be decided).
- Consumes `DonationAuthorized` idempotently and writes a donation ledger entry.
- Computes personal impact (per user) and aggregated impact (per company and per challenge, no names).

**Frontend (`frontend`)**
- Login and company join flow.
- Challenge list with filters (personal, group, open, completed).
- Survey view and completion (questions are loaded from `challenge`, answers are submitted to `participation`).
- Impact dashboards for the user and for the company representative.
- Challenge creation form for the representative.

**Responsibility split between Challenge and Participation (decided)**

`challenge` knows what is asked and what it is worth, plus the collective result. `participation` knows what one user did and whether it counts. Anything that needs other users' data (group progress, remaining budget, donation decision) belongs to `challenge`. Anything about a single user's submission (the attempt, validation, repeat-prevention, history) belongs to `participation`.

`participation` stays a separate service. Per-user attempts and group-wide counters are different consistency problems, and `participation` now owns validation and a copy of the challenges, so it is not a thin service.

Validation lives in `participation`, against a read-only copy of the challenges that it builds from events. `challenge` does not validate and is not called when a user completes a challenge. This means:
- `participation` does not depend on `challenge` at runtime, except for the bootstrap at startup. If `challenge` is down, users can still complete the challenges `participation` already knows.
- The copy is eventually consistent. A newly created challenge may be unknown to `participation` for a short time, and a submission for it is rejected until the event arrives.
- `participation` has to understand what it receives (questions and validation rules), so the exact fields are a fixed contract between the two services, documented in `api/`. The databases are not coupled: `participation` stores the received fields in its own normal columns and never sees how `challenge` stores a challenge. A change to the contract is a deliberate change to both services, see 1.12 item 11.
- The copy holds only what validation needs (type, validity window, status, questions and their rules), never budget, goal, or progress. Those stay in `challenge`.
- Validation at completion and the later budget or goal check in the `ChallengeCompleted` handler can disagree, for example if the challenge runs out of budget in between. A valid submission that contributes nothing to a donation is a normal outcome, not an error.

### 2.2 Cross-service flow (the complex use case from the brief)

0. Beforehand, when a representative created the challenge, `challenge` stored it and emitted `ChallengePublished`. `participation` consumed the event and updated its read-only copy. (After a reboot, `participation` rebuilds the copy from the `challenge` snapshot endpoint.)
1. The user completes a group challenge in the frontend. The questions came from `challenge`, and the answers are submitted to `participation`.
2. `participation` validates the submission against its copy of the challenge. If it is valid and the user has not already completed the challenge, `participation` records the completion, writes a `ChallengeCompleted` event to its outbox, and publishes it.
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
- The service's OpenAPI spec (in its own repository) matches the implementation, and any difference from the planned contract in `general` is logged in `changelog/`.
- The stage document's checklist is fully ticked, or open items are moved to the next stage with a note.
- `plan.md` is updated if an infrastructure decision changed. Documents in `general` carry a content hash on line 3, recalculated with `scripts/doc-hash.sh` (see `CLAUDE.md`).
