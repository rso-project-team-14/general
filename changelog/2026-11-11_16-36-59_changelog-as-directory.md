# Changelog is a directory with one file per entry

Date: 2026-11-11 16:36:59 UTC

Replaced the single `CHANGELOG.md` with the `changelog/` directory to avoid merge conflicts. Each entry is its own file, named `YYYY-MM-DD_HH-MM-SS_short-title.md` (UTC, second precision), and contains the title, the date and time, and the description. Existing entries were split into files, using the commit times of the original changes as their timestamps. Updated `CLAUDE.md` (rules and the snippet for the other repositories) and the layout in `plan.md` section 1.4.
