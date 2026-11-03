#!/usr/bin/env bash
# Integrity lock for every file an agent reads as instructions (AGENTS.md, rules, skill).
#   integrity.sh lock DIR FILE...   scan FILEs (relative to DIR), then write DIR/.engineering-standards.sha256
#   integrity.sh verify [DIR]       every locked file matches its hash and still passes the scan
# The lock is committed: its git history is the record of every approved instruction change, and a
# hand edit that skips build.sh shows up as a hash mismatch.
set -euo pipefail

LOCK=.engineering-standards.sha256
# Instructions never need to fetch or execute anything. Keep in sync with $forbidden in install.ps1.
FORBIDDEN='\b(curl|wget|Invoke-WebRequest|Invoke-RestMethod|Invoke-Expression|iwr|irm|iex|eval|base64|certutil|bitsadmin)\b|https?://|\|[[:space:]]*(ba|z|da)?sh\b|\b(ba|z)?sh -c\b'
# Zero-width and bidi-override characters hide text from the human reviewer, not from the agent.
INVISIBLE=($'\xe2\x80\x8b' $'\xe2\x80\x8c' $'\xe2\x80\x8d' $'\xe2\x80\x8e' $'\xe2\x80\x8f'
           $'\xe2\x80\xaa' $'\xe2\x80\xab' $'\xe2\x80\xac' $'\xe2\x80\xad' $'\xe2\x80\xae'
           $'\xe2\x81\xa6' $'\xe2\x81\xa7' $'\xe2\x81\xa8' $'\xe2\x81\xa9' $'\xef\xbb\xbf')

sha() { if command -v sha256sum >/dev/null; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }

scan() {
  local bad=0 f
  for f in "$@"; do
    if grep -nHiE "$FORBIDDEN" "$f" >&2; then bad=1; fi
    if LC_ALL=C grep -nHF "${INVISIBLE[@]/#/-e}" "$f" >/dev/null; then
      echo "$f: invisible unicode character" >&2; bad=1
    fi
  done
  [ "$bad" -eq 0 ] || { echo "FAIL: forbidden content in agent instructions (see above)" >&2; return 1; }
}

case "${1:-}" in
  lock)
    cd "$2"; shift 2
    scan "$@"
    sha "$@" | sed 's/^\([0-9a-f]*\) [ *]/\1  /' > "$LOCK"  # Git Bash may print "hash *file"
    ;;
  verify)
    cd "${2:-$(dirname "${BASH_SOURCE[0]}")/..}"
    [ -s "$LOCK" ] || { echo "FAIL: no $LOCK in $(pwd)" >&2; exit 1; }
    sha -c --quiet "$LOCK" >&2 || { echo "FAIL: instruction files differ from $LOCK — run scripts/build.sh and review the diff" >&2; exit 1; }
    files=()
    while IFS= read -r line; do files+=("${line:66}"); done < "$LOCK"
    scan "${files[@]}"
    ;;
  *) echo "usage: integrity.sh lock DIR FILE... | verify [DIR]" >&2; exit 2 ;;
esac
