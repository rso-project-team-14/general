# The logic reaches the store through an interface

Date: 2026-11-11 20:43:22 UTC

Corrected the structure of a Go service in `plan.md` section 1.4. The earlier text said that `domain` uses neither `http` nor `store`, which wrongly suggested the logic cannot reach the database. Now `domain` defines an interface listing what it needs from storage, `store` implements it, and `main.go` creates the store and passes it to the logic, and the logic to the HTTP side. `domain` calls the store through the interface and does not import the `store` package, and a handler never uses the store directly, so the readiness check goes through the logic as well. This follows a decision made in conversation.
