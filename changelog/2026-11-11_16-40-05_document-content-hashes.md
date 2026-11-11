# Content hash on every document

Date: 2026-11-11 16:40:05 UTC

Every Markdown document in `general` (except the files in `changelog/`) now has a content hash on line 3, in the form `<!-- sha256: ... -->`. The hash is the SHA-256 of everything from line 4 to the end of the file, so agents and other repositories can check whether a document changed without reading it. Added `scripts/doc-hash.sh` (`update` recalculates and writes the hashes, `check` only verifies them). Documented in `CLAUDE.md` (working rule 8 and the "Document hashes" section) and in the layout and definition of done in `plan.md`. Hashes were added to `plan.md`, `CLAUDE.md`, and the stage documents.
