# Fixed contract between challenge and participation, no JSONB in participation

Date: 2026-11-11 17:07:36 UTC

The `ChallengePublished` event is defined by a fixed contract in `api/` and carries only the fields `participation` needs, not the whole challenge. `participation` stores them in normal columns of its PostgreSQL database, with no JSONB or free-form data. The databases are not coupled: `challenge` keeps its internal storage (MongoDB) to itself, and a change to the contract is a deliberate change to both services. Updated `plan.md` sections 1.7 (event catalog), 1.8 (no coupling between databases, read-only copy), and 2.1, and open decisions 11 and 13. Open decision 11 is now about how questions and validation rules fit the fixed fields and how a new challenge type is added. Note: `challenge` still uses MongoDB. The entry `2026-11-11_17-01-22_challenge-back-to-postgresql.md` describes a change that was reverted and does not apply.
