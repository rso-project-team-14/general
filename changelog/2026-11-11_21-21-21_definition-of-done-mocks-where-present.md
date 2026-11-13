# Definition of done: tests mock the database and clients, where they are present

Date: 2026-11-11 21:21:21 UTC

Added a short note in parentheses to the tests line of the definition of done in `plan.md` section 2.4: the integration tests of the REST API and the DB layer mock the database and the clients, and they apply only in the stages where those are already present, so Stage 1, which has no database and no client, has none of the database and client tests. The stage documents are unchanged. This addresses the second point of the review of the branch and follows a decision made in conversation.
