# Standard sections for every repository's CLAUDE.md

Date: 2026-11-11 18:59:51 UTC

Added standard sections to `plan.md` section 1.14 that every service and frontend repository copies at the start of its `CLAUDE.md`: "How to work in this repo" (plan before editing, simplicity, surgical changes, definition of done, ask when ambiguous, stay in scope, tests are truth, be concise), "Stack" (Go, REST/JSON, RabbitMQ, Docker, Helm, AKS; the database is filled in per service; a variant for the frontend), "What burned us before" (an empty guide that the agent fills only when the user instructs it), and "Keep this file honest". The old item 5 "Stack and conventions" is now "Conventions". Service repositories should add these sections when they create or update their `CLAUDE.md`.
