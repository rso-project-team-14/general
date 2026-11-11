# CLAUDE.md

This is the `general` repository of the Butterfly Give project (team 14).

## What this repository is

`general` is **only for documentation and planning**. It holds the overall structure of the system, the shared documentation, and the API contracts that are defined **before** implementation. It contains **no implementation code**. Every microservice has its own repository, and the frontend has its own repository too.

### What belongs here
- `plan.md`: the project plan. Shared infrastructure first, service internals and delivery stages at the end.
- `docs/stages/`: one document per delivery stage, linked from `plan.md`.
- `api/`: the planned API contracts between the microservices (endpoints, request and response shapes, event payloads), written before implementation. These are contract documents, not OpenAPI specs.
- `changelog/`: the log of every change to the files above, one file per entry (see below).
- Overall project management: GitHub issues that concern the whole project (agreements, practices, estimates, design).

### What does not belong here
- Service or frontend source code, Dockerfiles, Helm charts, or CI pipelines of a specific repository.
- OpenAPI specs. Once a service is implemented, its OpenAPI spec lives in the service repository, and **that spec and the code are the truth**. The contract here is the plan it was built from.
- Service-specific issues. They go to the repository of that service.

## Repositories of the project

| Repository | Content |
|---|---|
| `general` | This repo: documentation, planning, planned API contracts, project management |
| `company-service` | Company & Membership service |
| `challenge-service` | Challenge service |
| `participation-service` | Participation service |
| `impact-service` | Donation & Impact service |
| `frontend` | React + TypeScript frontend (repository to be created) |

Issues in the other repositories are named with the repository name as a prefix, for example `[challenge-service] Create CLAUDE.md file`.

## Working rules

1. **`plan.md` is the source of truth** for infrastructure, service responsibilities, and delivery stages. If a decision changes, change `plan.md`. Do not leave it contradicting other documents.
2. **Open decisions stay open.** Section 1.12 of `plan.md` lists unresolved questions. Do not resolve one silently. If the team decides it, move the result into the right section and remove it from the list.
3. **Every change to `plan.md`, `docs/`, or `api/` needs a new file in `changelog/` in the same commit.**
4. **Planned contracts live in `api/`.** Before implementation, change the contract here first, then log it. After implementation, the service's own OpenAPI spec is the truth, and this contract is not kept in sync automatically.
5. **Keep it planning-level.** Describe what and why. Leave how to the service repositories.
6. **Stage documents are separate files** in `docs/stages/` and are linked from `plan.md` section 2.3. Do not put stage detail into `plan.md`.
7. **Language:** documents are written in English. The original project brief (`RSO_Ekipa14_Butterfly.pdf`) is in Slovenian.

## Changelog

The `changelog/` directory is how the other repositories find out that something changed here. It is a directory, not one file, so that parallel changes do not cause merge conflicts. Rules:

- **One file per entry.** Never edit another entry to add a new one.
- **File name:** `YYYY-MM-DD_HH-MM-SS_short-title.md`. The timestamp is in UTC with second precision and comes first, so a plain alphabetical listing is chronological. The short title is lowercase words joined by hyphens that describe the content, for example `2026-11-09_20-42-57_challenge-uses-mongodb.md`.
- **File content:** the title as a heading, a `Date:` line with the same timestamp, then a description of what changed and which files or sections are affected.
- One entry per logical change. Do not rewrite old entries, except for typos.
- Add the entry in the same commit as the change.

## For the other repositories

Each service repository's own `CLAUDE.md` (and the frontend's) should tell Claude to keep in sync with this repository. Suggested text:

> Before implementing a feature, list the `changelog/` directory in the `general` repository (`rso-project-team-14/general`) and compare the newest file name with the one recorded below under "Last checked general changelog entry".
> - If there are files newer than that one (file names start with a UTC timestamp, so alphabetical order is chronological), read them, then re-read the parts of `plan.md`, `docs/`, and `api/` they affect. Apply any changes that concern this repository, then update the "Last checked" line to the newest file name.
> - If there are no newer files, do not re-read `plan.md`.
>
> Last checked general changelog entry: _none yet_
