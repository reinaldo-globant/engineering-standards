#!/usr/bin/env bash
# install.sh [target-repo]
#   no arg           -> installs the skill for Claude Code, user-wide (~/.claude/skills)
#   arg              -> copies Cursor rules + skill into that repo
#   --verify <dir>   -> checks an install against the lock it left behind
# Every install writes .engineering-standards.sha256 next to what it copied (scripts/integrity.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ "${1:-}" != --verify ] || exec "$ROOT/scripts/integrity.sh" verify "${2:?usage: install.sh --verify <dir>}"
"$ROOT/scripts/build.sh" >/dev/null

# the copied skill's files, relative to the directory the lock lives in
skill_files() { (cd "$1" && find "$2" -type f ! -name .DS_Store | sed 's#^\./##' | LC_ALL=C sort); }

if [ $# -eq 0 ]; then
  DEST="${CLAUDE_HOME:-$HOME/.claude}/skills/engineering-standards"
  mkdir -p "$(dirname "$DEST")"
  rm -rf "$DEST"
  cp -r "$ROOT/skills/engineering-standards" "$DEST"
  locked=()
  while IFS= read -r f; do locked+=("$f"); done < <(skill_files "$DEST" .)
  "$ROOT/scripts/integrity.sh" lock "$DEST" "${locked[@]}"
  echo "installed skill -> $DEST"
else
  TARGET="$1"
  [ -d "$TARGET" ] || { echo "no such directory: $TARGET" >&2; exit 1; }
  mkdir -p "$TARGET/.cursor/rules" "$TARGET/.claude/skills" "$TARGET/.github/instructions"
  cp "$ROOT/.cursor/rules/"*.mdc "$TARGET/.cursor/rules/"
  cp "$ROOT/.github/copilot-instructions.md" "$TARGET/.github/"
  cp "$ROOT/.github/instructions/"*.instructions.md "$TARGET/.github/instructions/"
  locked=(.github/copilot-instructions.md)
  for f in "$ROOT"/.cursor/rules/*.mdc; do locked+=(".cursor/rules/${f##*/}"); done
  for f in "$ROOT"/.github/instructions/*.instructions.md; do locked+=(".github/instructions/${f##*/}"); done
  if [ -e "$TARGET/AGENTS.md" ]; then
    HAD_AGENTS=1
  else
    HAD_AGENTS=0
    cp "$ROOT/AGENTS.md" "$TARGET/"
    locked+=(AGENTS.md)
  fi
  rm -rf "$TARGET/.claude/skills/engineering-standards"
  cp -r "$ROOT/skills/engineering-standards" "$TARGET/.claude/skills/"
  while IFS= read -r f; do locked+=("$f"); done < <(skill_files "$TARGET" .claude/skills/engineering-standards)
  "$ROOT/scripts/integrity.sh" lock "$TARGET" "${locked[@]}"
  echo "installed -> $TARGET: .cursor/rules/, .github/, .claude/skills/, .engineering-standards.sha256"
  [ "$HAD_AGENTS" -eq 0 ] || echo "note: AGENTS.md already existed, left untouched and unlocked — merge by hand"
fi
