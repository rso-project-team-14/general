# Correction: the services write OpenAPI specs, the api/ contract documents wait

Date: 2026-11-11 21:36:37 UTC

Corrects the entry "No API specs in Stage 1 and Stage 2", which was wrong. What Stage 1 and Stage 2 skip is the contract documents in the `api/` directory of `general`: the health and ping endpoints are implemented without a planned contract to generate them from, and those documents are written later, when the business logic is planned. The services still write their own OpenAPI specs, in their own repositories. Updated `docs/stages/stage-1-demo.md` (out of scope now names the contract documents, an OpenAPI spec for the health and ping endpoints is in scope, and a checklist item for agents was added) and `docs/stages/stage-2-database-and-calls.md` (out of scope now names the contract documents, and the spec of each service is kept up to date). The previous entry is not edited, and is superseded by this one. This follows a decision made in conversation.
