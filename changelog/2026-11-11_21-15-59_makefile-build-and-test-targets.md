# Makefile with build and test targets for the Go services

Date: 2026-11-11 21:15:59 UTC

Every Go service repository has a `Makefile` in its root with two targets and nothing more: `make build` (compiles the service into `bin/<service>`) and `make test` (runs the unit tests). Unit tests are always run through `make test`, by people, agents, and the pipeline. Other targets are added later when decided, and the Makefile does not build Docker images or deploy. Added "Makefile of a Go service" to `plan.md` section 1.4, with the reference Makefile. The `general` repository has no Go code, so no Makefile is created here. Updated item 5 (commands) of the `CLAUDE.md` contents in 1.14 to cover only commands beyond these targets, and Stage 1 (scope, tests, checklist) and Stage 2 (tests) to use `make test` instead of `go test ./...`. This follows a decision made in conversation.
