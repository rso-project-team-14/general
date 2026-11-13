# Participation stays a separate service

Date: 2026-11-11 19:38:39 UTC

Decided that `participation` stays a separate service: per-user attempts and group-wide counters are different consistency problems, and `participation` now owns validation and a copy of the challenges. Recorded in the responsibility split in `plan.md` section 2.1 and removed from the open decisions in 1.12. The open decisions after it were renumbered: the replication details are now item 12 and the location of the deployment files is now item 13. References in `plan.md` and Stage 1 were updated.
