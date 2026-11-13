# Stage 1: agents implement the code, the team does the deployment

Date: 2026-11-11 21:09:47 UTC

In `docs/stages/stage-1-demo.md`, added a "Who does what" section: agents only implement the code of Stage 1 (the four Go services with the structure from `plan.md` 1.4, the endpoints, the tests, and the frontend page), and the team does all the deployment itself, to learn it (Docker images, Helm charts, the AKS cluster, the GitHub Actions pipeline, and deploying and checking in the cloud). An agent does not write or change Dockerfiles, Helm charts, pipeline files, or cluster configuration for this stage. The deployment items in the scope are marked "done by the team", and the checklist is split into "Implementation (agents)" and "Deployment (the team)". Running `go test ./...` in the pipeline moved to the team's part. This follows a decision made in conversation.
