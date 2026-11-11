# Stage 1 is backend only

Date: 2026-11-11 20:28:37 UTC

The frontend is not implemented in Stage 1, which is now the backend only. Removed the frontend ping page, the frontend Docker image, and the `frontend` repository from the scope and checklist of `docs/stages/stage-1-demo.md`, and added the frontend to the out-of-scope list. The check that Stage 1 works is now that the ping endpoint of each service answers when called from outside the cluster. Updated the Stage 1 row in the stage table in `plan.md` section 2.3. This follows a decision made in conversation.
