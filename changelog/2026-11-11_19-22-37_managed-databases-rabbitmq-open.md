# PostgreSQL and MongoDB are managed; RabbitMQ hosting stays open

Date: 2026-11-11 19:22:37 UTC

PostgreSQL and MongoDB are managed services, not run inside the cluster, so the Helm charts deploy no database and each service reads its connection details from a Kubernetes Secret. Which managed products are used is still to be chosen. RabbitMQ hosting (inside the cluster or a managed service) remains an open decision. Updated `plan.md` section 1.10 and open decision 2 (now about RabbitMQ hosting), and the scope and open decisions in Stage 1.
