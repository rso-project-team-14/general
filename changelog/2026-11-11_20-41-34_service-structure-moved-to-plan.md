# Structure of a Go service is described in the plan, Stage 1 follows it

Date: 2026-11-11 20:41:34 UTC

Moved the description of the structure of a Go service from Stage 1 to `plan.md` section 1.4 ("Structure of a Go service": `cmd/<service>/main.go`, `internal/config`, `internal/domain`, `internal/http`, `internal/store`, the one-way dependencies, and how an endpoint is added), so the plan holds the only copy. Stage 1 no longer defines the structure. It starts following the one in the plan: updated the goal, the scope, and the checklist of `docs/stages/stage-1-demo.md`, and kept the mock tests there. The plan text is general. The Stage 1 specifics (the logic only builds the ping answer, the database side only provides the readiness check) stay in Stage 1. This follows a decision made in conversation.
