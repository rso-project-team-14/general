# CLAUDE.md

This is the `general` repository of the Butterfly Give project (team 14).

## What this repository is

`general` is **only for planning and project management**. It holds the overall structure of the system, the shared documentation, and the contracts between the microservices. It contains **no implementation code**. The microservices live in their own repositories.

### What belongs here
- `plan.md`: the project plan. Shared infrastructure first, service internals and delivery stages at the end.
- `docs/stages/`: one document per delivery stage, linked from `plan.md`.
- `api/`: API contracts and specs between the microservices (OpenAPI files, event contracts).
- `CHANGELOG.md`: the log of every change to the files above (see below).
- Overall project management: GitHub issues that concern the whole project (agreements, practices, estimates, design).

### What does not belong here
- Service source code, Dockerfiles, Helm charts, or CI pipelines of a specific service. These go to the service repositories.
- Service-specific issues. They go to the repository of that service.

## Repositories of the project

| Repository | Service |
|---|---|
| `general` | This repo: planning, contracts, project management |
| `company-service` | Company & Membership |
| `challenge-service` | Challenge |
| `participation-service` | Participation |
| `impact-service` | Donation & Impact |

Issues in the service repositories are named with the repository name as a prefix, for example `[challenge-service] Create CLAUDE.md file`.

## Working rules

1. **`plan.md` is the source of truth** for infrastructure, service responsibilities, and delivery stages. If a decision changes, change `plan.md`. Do not leave it contradicting other documents.
2. **Open decisions stay open.** Section 1.12 of `plan.md` lists unresolved questions. Do not resolve one silently. If the team decides it, move the result into the right section and remove it from the list.
3. **Every change to `plan.md`, `docs/`, or `api/` needs a `CHANGELOG.md` entry in the same commit.**
4. **API contracts live in `api/`.** When an endpoint or event payload changes, change the contract here first, then log it.
5. **Keep it planning-level.** Describe what and why. Leave how to the service repositories.
6. **Stage documents are separate files** in `docs/stages/` and are linked from `plan.md` section 2.3. Do not put stage detail into `plan.md`.
7. **Language:** documents are written in English. The original project brief (`RSO_Ekipa14_Butterfly.pdf`) is in Slovenian.

## Changelog

`CHANGELOG.md` is how the service repositories find out that something changed here. Rules:

- Newest entry on top.
- Each entry starts with the **date** (`YYYY-MM-DD`), then a short **title**, then a **description** of what changed and which files or sections are affected.
- One entry per logical change. Do not rewrite old entries, except for typos.
- Add the entry in the same commit as the change.

## Git workflow

- GitHub Flow: `main` is always deployable, work happens on short-lived branches merged through pull requests. There is no long-living `dev` branch. See `plan.md` section 1.13.
- Staging and production are GitHub Environments, not branches.
- Conventional Commits are assumed (still to be confirmed in issue #5).

## For the service repositories

Each service repository's own `CLAUDE.md` should tell Claude to keep in sync with this repository. Suggested text:

> Before implementing a feature, open `CHANGELOG.md` in the `general` repository (`rso-project-team-14/general`) and compare it with the last entry recorded below under "Last checked general changelog entry".
> - If there are newer entries, read them, then re-read the parts of `plan.md`, `docs/`, and `api/` they affect. Apply any changes that concern this service, then update the "Last checked" line.
> - If there are no newer entries, do not re-read `plan.md`.
>
> Last checked general changelog entry: _none yet_
