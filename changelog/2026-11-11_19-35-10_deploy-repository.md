# A separate deploy repository holds the Helm charts

Date: 2026-11-11 19:35:10 UTC

Decided that the Helm charts and everything about deploying live in a separate `deploy` repository (to be created), not in `general` and not in the service repositories. It holds the umbrella chart, the per-service charts, the values per environment, the deploy workflows, and the `staging` and `production` GitHub Environments with their secrets. Service repositories build, test, and push images, and `deploy` runs `helm upgrade --install`. Added the repository to `plan.md` section 1.4 and to `CLAUDE.md`, rewrote the workflows in section 1.11, and added a note for the `deploy` repository's `CLAUDE.md` in 1.14. Open decision 12 (where the deployment files live) is resolved and removed. New open decision 14: how `deploy` learns about a new image. Stage 1 checklist updated. The local development setup remains TBD (1.5).
