# No API specs in Stage 1 and Stage 2

Date: 2026-11-11 21:35:39 UTC

Noted in `docs/stages/stage-1-demo.md` and `docs/stages/stage-2-database-and-calls.md` that no API specs are written in these stages: nothing is written to the `api/` directory of `general` and no OpenAPI spec is written. The specs are written later, when the business logic is implemented. The health and ping endpoints are simple and need no spec. In Stage 1 this replaces the earlier wording "OpenAPI beyond the ping and health endpoints", which implied that a spec for them was in scope. The contract documents in `api/` stay as the TO DO skeletons. This follows a decision made in conversation and addresses a possible problem raised in the review of the branch.
