# CLAUDE.md has no content hash

Date: 2026-11-11 16:41:37 UTC

`CLAUDE.md` is excluded from the content hash rule because no other repository reads it. Removed its hash line. `scripts/doc-hash.sh` skips it, and the "Document hashes" section of `CLAUDE.md` lists it as an exception. The hash on line 3 still applies to `plan.md`, the stage documents, and the other Markdown documents.
