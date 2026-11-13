# Validation moved to the challenge service

Date: 2026-11-09 21:05:06 UTC

Submission validation now lives in the `challenge` service. `participation` stores answers as opaque data and calls `POST /api/v1/challenges/{id}/validate-submission` before recording a completion. `challenge` is on the critical path at completion. `answersValid` removed from the `ChallengeCompleted` payload. Updated `plan.md` sections 1.3, 1.7, 2.1, and 2.2. Added open decisions 7 to 11 (donation timing, personal challenges, `userId` in events, validity window race, whether `participation` stays separate).
