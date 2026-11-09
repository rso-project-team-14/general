# Stage 2: Minimum viable product

Back to [plan.md](../../plan.md). Previous stage: [Stage 1](stage-1-demo.md).

## Goal

A usable product for one company. Real users log in, join a company with an invite code, complete challenges under the real rules, and see their impact. Events are delivered reliably and processed idempotently. Contracts are written in OpenAPI.

## Scope

### In scope
- Authentication with JWT issued by `company-membership` (plan 1.12 item 1, option a).
- Company creation, invite codes, and membership roles (`employee`, `representative`).
- Challenge creation and publishing by a representative: personal and group types, validity period, goal, budget, amount per success.
- Personal challenges and group challenge progress.
- Repeat-prevention: a user can complete a given challenge once per validity window.
- Budget check: a donation is authorized only if the remaining budget covers it.
- Transactional outbox in `participation` and `challenge-campaign`.
- Idempotent consumers with `processed_events` in `challenge-campaign` and `donation-impact`.
- Charity organizations: seeded plus an admin endpoint (plan 1.12 item 4).
- Aggregated company impact with counts and sums only.
- OpenAPI contracts finalized for every endpoint.
- Frontend screens for every use case in the brief (section 5 of the project PDF).

### Out of scope
- Kubernetes, Helm, AKS, and cloud CI/CD (Stage 3).
- Email notifications, password reset, SSO.
- Multiple currencies (plan 1.12 item 5).

## Service behavior

### company-membership
- `POST /api/v1/auth/register`, `POST /api/v1/auth/login` (returns JWT with `sub`, `companyId`, `role`).
- `POST /api/v1/companies` (creates company, caller becomes `representative`).
- `POST /api/v1/companies/{companyId}/invite-codes` (random code, expiry, use limit).
- `POST /api/v1/companies/join` (body: invite code).
- `GET /api/v1/memberships/me`.
- Internal REST: `GET /api/v1/companies/{companyId}/members/{userId}` for other services.

### challenge-campaign
- `POST /api/v1/challenges` (representative only). Validates goal > 0, budget ≥ amount per success.
- `POST /api/v1/challenges/{id}/publish`.
- `GET /api/v1/challenges?type=&status=` (filter: personal, group, open, completed).
- `GET /api/v1/challenges/{id}/progress` (group progress for the company).
- Consumes `ChallengeCompleted`:
  - Idempotency check in `processed_events`.
  - Updates group progress.
  - When the goal is reached and budget covers the amount, decreases remaining budget and writes `DonationAuthorized` to the outbox, in one transaction.

### participation
- `POST /api/v1/participations` (start).
- `POST /api/v1/participations/{id}/answers` (survey answers, validated against the challenge's question set).
- `POST /api/v1/participations/{id}/complete`:
  - Checks answers are complete and valid.
  - Checks repeat-prevention for the user and challenge.
  - Writes `ChallengeCompleted` to the outbox, in one transaction with the completion.
- Outbox publisher loop: reads unsent rows, publishes to `butterfly.events`, marks them sent.

### donation-impact
- `GET /api/v1/organizations`, `POST /api/v1/admin/organizations` (admin only).
- Consumes `DonationAuthorized`, idempotent, writes a ledger row in `donations`.
- `GET /api/v1/impact/me`: personal totals.
- `GET /api/v1/impact/companies/{companyId}`: company totals, no user identifiers in the response.
- `GET /api/v1/impact/campaigns/{campaignId}`: campaign totals.

### frontend
- Login, register, join company with code.
- Challenge list and detail, survey UI, completion result.
- Personal impact page.
- Representative area: create and publish challenge, view company impact.

## Data model (draft)

| Database | Main tables |
|---|---|
| `company_db` | `companies`, `users`, `memberships`, `invite_codes` |
| `challenge_db` | `challenges`, `challenge_questions`, `group_progress`, `campaigns`, `outbox`, `processed_events` |
| `participation_db` | `participations`, `answers`, `outbox` |
| `impact_db` | `organizations`, `donations`, `processed_events` |

Users are stored in `company_db` only. Other services refer to users by `userId` (UUID) from the JWT.

## Testing

- Domain unit tests: rules for validity, repeat-prevention, budget, goal progress.
- Repository tests against a real PostgreSQL (testcontainers or the compose DB).
- Consumer tests: the same event delivered twice produces one effect.
- Outbox test: a failed publish is retried and the event is not lost.
- Contract check: OpenAPI validated in CI.

## Checklist

- [ ] JWT auth works across services (each service validates the token with the shared signing key from its Secret)
- [ ] Company creation, invite codes, and join flow implemented
- [ ] Challenge CRUD and publish for representatives
- [ ] Personal and group challenge flows implemented, including repeat-prevention
- [ ] Budget rule enforced in `challenge-campaign`
- [ ] Transactional outbox in `participation` and `challenge-campaign`
- [ ] Idempotent consumers in `challenge-campaign` and `donation-impact`
- [ ] Charity organizations seeded and manageable by admin
- [ ] Aggregated company impact returns no personal identifiers
- [ ] OpenAPI files complete and validated in CI
- [ ] Unit and integration tests pass locally
- [ ] Frontend covers every use case in the brief

## Open decisions this stage depends on

- Plan 1.12 item 1 (auth model): option (a) assumed.
- Plan 1.12 item 4 (charity organizations): seeded plus admin endpoint assumed.
- Plan 1.12 item 5 (currency): EUR assumed.
