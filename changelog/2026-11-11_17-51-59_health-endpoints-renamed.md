# Health endpoints: /health/started, /health/ready, /health/live

Date: 2026-11-11 17:51:59 UTC

Replaced `/healthz` and `/readyz` with three endpoints, one per Kubernetes probe type: `GET /health/started` (startup finished), `GET /health/ready` (database and RabbitMQ reachable), and `GET /health/live` (process alive, no dependency checks). The `participation` challenge bootstrap now gates `/health/started` instead of readiness. Updated `plan.md` sections 1.6, 1.10, 2.1, and open decision 13, and the endpoints and checklist in Stage 1.
