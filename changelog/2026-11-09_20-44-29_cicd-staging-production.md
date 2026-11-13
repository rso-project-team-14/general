# CI/CD with staging and production environments

Date: 2026-11-09 20:44:29 UTC

GitHub Actions deploys to two GitHub Environments, `staging` and `production`. Merge to `main` deploys to `staging`, then the same image tags are promoted to `production`. Updated `plan.md` sections 1.11 and 1.13. Open question: manual approval or automatic promotion.
