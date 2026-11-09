# Changelog

Changes to the planning documents, stage documents, and API contracts in this repository. Newest first. See `CLAUDE.md` for the rules.

Each entry: date, title, description.

---

## 2026-11-09: Repository is planning only; multi-repo layout

`general` is declared the planning and project-management repository, with no implementation code (new `CLAUDE.md`). Section 1.4 of `plan.md` now describes the multi-repo layout: `general` holds the plan, stage documents, and API contracts, and each service has its own repository. Added this changelog. The location of the frontend and of deployment files (Helm, docker-compose) is a new open decision (`plan.md` 1.12 item 12). Stage 1 checklist adjusted.

## 2026-11-09: Validation moved to the challenge service

Submission validation now lives in the `challenge` service. `participation` stores answers as opaque data and calls `POST /api/v1/challenges/{id}/validate-submission` before recording a completion. `challenge` is on the critical path at completion. `answersValid` removed from the `ChallengeCompleted` payload. Updated `plan.md` sections 1.3, 1.7, 2.1, and 2.2. Added open decisions 7 to 11 (donation timing, personal challenges, `userId` in events, validity window race, whether `participation` stays separate).

## 2026-11-09: Campaign concept removed

The campaign concept is dropped. The service "Challenge & Campaign" (`challenge-campaign`) is now "Challenge" (`challenge`). `campaignId` in the `DonationAuthorized` payload is now `challengeId`. Impact is aggregated per company and per challenge. Updated `plan.md` and Stage 1.

## 2026-11-09: CI/CD with staging and production environments

GitHub Actions deploys to two GitHub Environments, `staging` and `production`. Merge to `main` deploys to `staging`, then the same image tags are promoted to `production`. Updated `plan.md` sections 1.11 and 1.13. Open question: manual approval or automatic promotion.

## 2026-11-09: Challenge service uses MongoDB

`challenge` uses MongoDB (`challenge_db`) for challenges with varied, unpredictable shapes. The other services keep PostgreSQL. Updated the stack, local setup, data rules, idempotency and outbox notes, and open decisions in `plan.md`, and Stage 1.

## 2026-11-09: Branching strategy

GitHub Flow with a staging environment through GitHub Environments and no feature flags. Added as `plan.md` section 1.13 (source: issue #8).

## 2026-11-09: Plan initialized

Created `plan.md` (shared infrastructure, then service internals and delivery stages) and the stage documents in `docs/stages/`. Stage 1 is a basic cloud demo with no business logic. Stages 2 and 3 are empty placeholders to be planned later.
