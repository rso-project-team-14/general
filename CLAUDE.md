# CLAUDE.md

This is the `general` repository of the Butterfly Give project (team 14).

## What this repository is

`general` is **only for documentation and planning**. It holds the overall structure of the system, the shared documentation, and the API contracts that are defined **before** implementation. It contains **no implementation code**. Every microservice has its own repository, and the frontend has its own repository too.

### What belongs here
- `plan.md`: the project plan. Shared infrastructure first, service internals and delivery stages at the end.
- `docs/stages/`: one document per delivery stage, linked from `plan.md`.
- `api/`: the planned API contracts between the microservices (endpoints, request and response shapes, event payloads), written before implementation. These are contract documents, not OpenAPI specs.
- `changelog/`: the log of every change to the files above, one file per entry (see below).
- `scripts/`: small tools for maintaining the documents, such as `scripts/doc-hash.sh` (see "Document hashes").
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
8. **Run `scripts/doc-hash.sh` after changing any document and before committing.** Never edit or calculate a hash by hand (see "Document hashes").
9. **Documents state the current decision, not where it came from.** Do not cite sources (an issue, a comment, the project brief) in `plan.md`, `docs/`, or `api/`. Write the source in the changelog entry for that change. A pointer that says where an open item is being discussed (for example "still to be agreed in issue #5") is fine, because it is not a source.

## Document hashes

Every Markdown document in this repository carries a content hash on line 3, so that people and agents can tell whether a document changed without reading it. Exceptions: this file (`CLAUDE.md`), which is never read by other repositories, the files in `changelog/`, which are written once and not changed, and the PDF.

Layout of a document:

```
line 1    # Title
line 2    (blank)
line 3    <!-- sha256: <64 hex characters> -->
line 4+   content
```

- The hash is the SHA-256 of everything from **line 4 to the end of the file**, byte for byte. Lines 1 to 3 are not hashed, so changing only the title does not change the hash.
- Files use LF line endings.
- **Always use the script, never calculate by hand:**
  - `scripts/doc-hash.sh` (or `scripts/doc-hash.sh update`) recalculates the hashes of all documents and writes them. A new document only needs a title on line 1 and a blank line 2. The script inserts the hash line.
  - `scripts/doc-hash.sh check` verifies the hashes, changes nothing, and exits with 1 if any is wrong. This is the command for external systems and agents.
- To see whether a document changed since you last read it, compare the hash on line 3 with the one you recorded. If they are equal, do not re-read the file.

## Changelog

The `changelog/` directory is how the other repositories find out that something changed here. It is a directory, not one file, so that parallel changes do not cause merge conflicts. Rules:

- **One file per entry.** Never edit another entry to add a new one.
- **File name:** `YYYY-MM-DD_HH-MM-SS_short-title.md`. The timestamp is in UTC with second precision and comes first, so a plain alphabetical listing is chronological. The short title is lowercase words joined by hyphens that describe the content, for example `2026-11-09_20-42-57_challenge-uses-mongodb.md`.
- **File content:** the title as a heading, a `Date:` line with the same timestamp, then a description of what changed and which files or sections are affected. If the change comes from a source (an issue or comment link, the project brief, a decision made in conversation), name it here.
- One entry per logical change. Do not rewrite old entries, except for typos.
- Add the entry in the same commit as the change.

## For the other repositories

Each service repository and the frontend repository has its own `CLAUDE.md`. What it must contain, including the suggested text that makes Claude keep in sync with this repository's changelog, is defined in `plan.md` section 1.14. That is the only copy, so update it there.
