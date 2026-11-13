# Challenge service back to PostgreSQL, fixed schema and contract-based events

Date: 2026-11-11 17:01:22 UTC

Reverses the MongoDB decision. Challenges have a defined schema, because `challenge` sends `participation` only the data it needs, and the exact fields are a contract in `api/`. There is no flexible challenge shape, so `challenge` uses PostgreSQL like the other services, and there is no coupling between the databases. Removed MongoDB from the stack, local setup, configuration, idempotency and outbox notes, data rules, and the open decision on data services in `plan.md`, and from Stage 1. `participation` keeps only the contract fields of each challenge in its own tables, not JSONB. `ChallengePublished` now carries the contract fields, not the full definition. Open decision 11 was rewritten (how a new challenge type is introduced with a fixed schema).
