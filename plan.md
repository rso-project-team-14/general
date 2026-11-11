# Butterfly Give: Project Plan

<!-- sha256: 9c345067af439d28722e733435884c287b62ec56cc41815ac984a6d99ddb964e -->

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
- `participation` does not call `challenge` while users complete challenges. It keeps its own read-only copy of the challenges, built from `ChallengePublished` events. The only synchronous call is the bootstrap at startup (see 1.7 and 1.12 item 12).

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
├── changelog/                      # one file per change, a historical record for people
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

Event catalog:

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
2. **Hosting of the data services:** PostgreSQL and MongoDB are already decided as managed services (see 1.10), but which managed products to use is still to be chosen. Needed for Stage 1. RabbitMQ hosting is also still to be decided: run it inside the cluster (installed with Helm or an operator), or use a managed RabbitMQ service from a third party. Not needed for Stage 1.
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

**Branching model: GitHub Flow.**
- `main` is the only long-lived branch and is always deployable.
- All work happens on short-lived branches created from `main` and merged back through a pull request.
- A long-living `dev` branch is deliberately **not** used: long-living branches drift away from production code.

**Branch naming convention:**

```
<initials>/<type>-<descriptive-name>
```

- `<initials>`: the first letter of the first name and the first letter of the surname of the person who owns the branch.
- `<type>`: the kind of change, such as `feat` or `fix` (the comment says "feat/fix/etc.", without listing every type).
- `<descriptive-name>`: a short name that says what the branch is for.
- Example, for a person with initials AB: `ab/feat-add-health-endpoints`.

**Staging through GitHub Environments, not branches.**
- Two environments exist: `staging` and `production`. `staging` lets the microservices be tested together in a realistic setting before release.
- Both are implemented with GitHub Environments (for environment-scoped secrets, variables, and optional approvals), not with separate branches.
- Changes merged to `main` deploy to `staging` first. Promotion to `production` is a separate workflow step, see 1.11.

**Feature flags are not used.**
- Deployment and release do not need to be decoupled in this project, and flags would make the code harder to read.
- Unfinished work stays on its branch until it is ready to merge, so branches must stay small and short-lived.

**Still to be agreed in issue #5** (the issue only settled the model above):
- Pull request and review rules (required approvals, required checks, merge method).
- Commit format. Conventional Commits is already assumed in #5.
- Whether promotion from `staging` to `production` needs a manual approval (required reviewers) or is automatic.

### 1.14 CLAUDE.md in every repository

Every service repository and the frontend repository has its own `CLAUDE.md`, created when the repository is initialized (for example with `/init`, then completed from this list). **Nothing that is written in this plan is repeated in a `CLAUDE.md`.** That includes a convention such as UUID v4 or the port, the stack, and any rule from 1.8 or 1.13. The `CLAUDE.md` links to the plan section instead, so the plan stays the only copy and the two cannot drift apart. A `CLAUDE.md` contains only what is specific to its repository and is not in the plan. The standard sections below are the template itself and are copied as they are.

**Standard sections (the start of every `CLAUDE.md`)**

These four sections are the same in every repository. Copy them as written.

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

- The shared stack and the conventions are in `plan.md` (sections 1.2 and 1.6) in the `general` repository. Do not repeat them here.
- Add here only what the plan does not say: the Go version, the libraries chosen in this repository, and the build tooling.
- Prefer the repo's existing libraries over reaching for a new dependency.
- Don't infer the build tooling or the module layout. Read the repo.

## What burned us before

<!-- Guide for the agent: nothing is recorded yet. Do not add anything here on your own and do not invent incidents.
     When the user tells you to add an entry, write one short line: what went wrong, and the check that would have caught it.
     Example of the shape (not a real incident): "A job reported success while some records were skipped. Verify counts after bulk operations." -->

## Keep this file honest

- When you get corrected, add the lesson to this file (update CLAUDE.md) so the next session starts ahead.
````

After the standard sections, add the repository-specific items below. They are links and specifics, never copies of the plan.

A service's `CLAUDE.md` should contain:

1. **Purpose and place.** Which service this repository is (the short name from 1.3) and a link to its part of section 2.1 once that section is written. Do not copy the description of its responsibility.
2. **Link to `general`.** The repository `rso-project-team-14/general`, where the plan lives, with a pointer to `plan.md` as the source of truth. Nothing more. In particular, no summary of the plan, and no restating of the git workflow, which is in 1.13.
3. **Dependencies on `general` (required).** A table of the files in `general` that this repository depends on, each with a link and the hash recorded when the file was last read in full. The files are `plan.md`, the API contracts it depends on (its own and those of the services it talks to), and the stage document it is implementing. The suggested text below defines how the hashes are checked.
4. **Repository specifics.** Only what is specific to this repository and is not in the plan: the language version, the internal layout of the repository, where the migrations live, deviations from the conventions in 1.6, and implementation choices for the events and data rules in 1.7 and 1.8. Never restate a convention or rule from the plan (for example UUID v4, the port, the health endpoints, money in cents, the database-per-service rule). If this repository has to differ from the plan, say so here as a deviation, and report it as a change in `general`.
5. **Commands.** How to build, test, lint, run, and apply migrations. Marked TBD until local development (1.5) is decided.
6. **Rules for Claude.** Only rules about behavior that are not in the plan:
    - Stay within this service's responsibility.
    - Do not resolve an open decision from 1.12 silently. Raise it as an issue or a change in `general`.
    - If the plan looks wrong or contradicts the code, say so instead of quietly diverging from it.
    - Never commit secrets.

The frontend's `CLAUDE.md` uses the same items. Its repository specifics (item 4) are things like the package manager once it is decided, and the contracts of the services it calls are rows in the dependency table (item 3).

Suggested text for the dependencies (item 3):

> ## Documents from `general` this repository depends on
>
> These files in the `general` repository (`rso-project-team-14/general`, branch `main`) describe what this repository implements. Each one has a content hash on line 3. "Last read hash" is the hash from the last time the file was read in full.
>
> | File | Link | Last read hash |
> |---|---|---|
> | `plan.md` | `https://github.com/rso-project-team-14/general/blob/main/plan.md` | _none yet_ |
> | `api/<this-service>.md` | `https://github.com/rso-project-team-14/general/blob/main/api/<this-service>.md` | _none yet_ |
> | `docs/stages/<current-stage>.md` | `https://github.com/rso-project-team-14/general/blob/main/docs/stages/<current-stage>.md` | _none yet_ |
>
> Before implementing a feature, check each file in the table:
> 1. Read only line 3 of the file. For example: `curl -s https://raw.githubusercontent.com/rso-project-team-14/general/main/plan.md | sed -n 3p`. It looks like `<!-- sha256: ... -->`.
> 2. If the hash is the same as "Last read hash", the file did not change. Do not re-read it.
> 3. If it is different, or the recorded hash is `none yet`, read the whole file and apply the changes that concern this repository. Then write the new hash into the table.
>
> The `changelog/` directory in `general` is a historical record for people. Do not use it to detect changes. Read an entry only when you need to understand why something was changed.

---

## Part 2: Microservice internals and delivery stages

### 2.1 Internal logic of each service

TO DO. This section is empty on purpose. The internal logic of each service will be planned together with the user stories and the description of how the application should work. Nothing here is decided yet.

### 2.2 Cross-service flow

TO DO. This section is empty on purpose. The flows between the services will be planned together with the user stories and the description of how the application should work. Nothing here is decided yet.

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
