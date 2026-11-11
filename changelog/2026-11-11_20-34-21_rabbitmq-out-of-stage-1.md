# RabbitMQ is out of Stage 1

Date: 2026-11-11 20:34:21 UTC

RabbitMQ is not part of Stage 1. In `docs/stages/stage-1-demo.md`, removed the RabbitMQ instance from the scope and added RabbitMQ to the out-of-scope list. `/health/ready` now checks only the service's database in this stage, and the readiness item in the checklist was changed accordingly. In `plan.md` open decision 2, RabbitMQ hosting is marked as not needed for Stage 1, while the choice of managed products for PostgreSQL and MongoDB is still needed. The general health convention in section 1.6 (readiness checks the database and RabbitMQ) is unchanged. This follows a decision made in conversation.
