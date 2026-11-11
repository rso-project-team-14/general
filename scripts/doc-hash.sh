#!/usr/bin/env bash
#
# Keeps the content hash on line 3 of every Markdown document in this
# repository up to date.
#
# Format of a document:
#   line 1   title (`# Title`)
#   line 2   blank
#   line 3   <!-- sha256: <64 hex characters> -->
#   line 4+  content
#
# The hash is the SHA-256 of everything from line 4 to the end of the file,
# byte for byte. Lines 1 to 3 are not hashed.
#
# Documents covered: every *.md file in the repository except those in
# changelog/ (changelog entries are written once and not changed).
#
# Usage:
#   scripts/doc-hash.sh            recalculate and write the hashes (same as "update")
#   scripts/doc-hash.sh update     recalculate and write the hashes
#   scripts/doc-hash.sh check      verify the hashes, change nothing, exit 1 on a mismatch
#
# Run "update" before every commit that changes a document.

set -euo pipefail

cd "$(dirname "$0")/.."

HASH_LINE_RE='^<!-- sha256: [0-9a-f]{64} -->$'

if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 | cut -d' ' -f1; }
else
  echo "error: neither sha256sum nor shasum is available" >&2
  exit 2
fi

list_docs() {
  find . -type f -name '*.md' \
    -not -path './.git/*' \
    -not -path './changelog/*' \
    | sed 's|^\./||' | LC_ALL=C sort
}

has_hash_line() {
  [[ "$(sed -n '3p' "$1")" =~ $HASH_LINE_RE ]]
}

# Hash of everything from line 4 to the end of an existing, already hashed file.
body_hash() {
  tail -n +4 "$1" | sha256
}

check_file_is_valid() {
  local f="$1"
  if grep -q $'\r' "$f"; then
    echo "error: $f contains CR characters, use LF line endings" >&2
    return 1
  fi
  if [ "$(wc -l < "$f")" -lt 2 ]; then
    echo "error: $f needs at least a title line and a blank line" >&2
    return 1
  fi
  if [ "$(sed -n '2p' "$f")" != "" ]; then
    echo "error: $f must have a blank line 2 (title on line 1)" >&2
    return 1
  fi
  return 0
}

update_file() {
  local f="$1" tmp body hash
  check_file_is_valid "$f" || return 1
  tmp="$(mktemp)"
  body="$(mktemp)"
  if has_hash_line "$f"; then
    tail -n +4 "$f" > "$body"
  else
    # No hash yet: insert it on line 3, followed by a blank line 4.
    { printf '\n'; tail -n +3 "$f"; } > "$body"
  fi
  hash="$(sha256 < "$body")"
  { head -n 2 "$f"; printf '<!-- sha256: %s -->\n' "$hash"; cat "$body"; } > "$tmp"
  rm -f "$body"
  if cmp -s "$tmp" "$f"; then
    rm -f "$tmp"
    echo "unchanged  $f"
  else
    cat "$tmp" > "$f"
    rm -f "$tmp"
    echo "updated    $f  $hash"
  fi
}

check_file() {
  local f="$1" stored actual
  check_file_is_valid "$f" || return 1
  if ! has_hash_line "$f"; then
    echo "missing    $f (line 3 is not a hash line)"
    return 1
  fi
  stored="$(sed -n '3p' "$f" | sed -E 's/^<!-- sha256: ([0-9a-f]{64}) -->$/\1/')"
  actual="$(body_hash "$f")"
  if [ "$stored" = "$actual" ]; then
    echo "ok         $f"
  else
    echo "MISMATCH   $f  stored=$stored actual=$actual"
    return 1
  fi
}

mode="${1:-update}"
status=0
while IFS= read -r f; do
  case "$mode" in
    update) update_file "$f" || status=1 ;;
    check)  check_file "$f"  || status=1 ;;
    *) echo "usage: $0 [update|check]" >&2; exit 2 ;;
  esac
done < <(list_docs)

exit "$status"
