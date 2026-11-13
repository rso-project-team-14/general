# No monorepo; general is documentation only

Date: 2026-11-09 21:17:09 UTC

Removed the monorepo description from `plan.md`. Section 1.4 now states that every microservice and the frontend each have their own repository (`frontend` to be created), and `general` holds documentation only. Planned API contracts live in `general/api/` as contract documents, not OpenAPI specs. After implementation, the truth is the service's code and its own OpenAPI spec. Updated the stack table, the definition of done, open decision 12 (now only about deployment files), and the Stage 1 checklist. Removed the Git workflow section from `CLAUDE.md`; the branching strategy stays in `plan.md` 1.13 only.
