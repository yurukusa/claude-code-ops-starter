#!/usr/bin/env bash
# uninstall.sh — Remove Fix Bundle Teaser hooks
# Only removes the 2 teaser hooks. Does not touch Ops Starter or other hooks.
set -euo pipefail

HOOK_DIR="${HOME}/.claude/hooks"

HOOKS=(
  "session-saver.sh"
  "git-auto-backup.sh"
)

echo "Fix Bundle Teaser Uninstaller"
echo "============================="
echo ""

REMOVED=0

for hook in "${HOOKS[@]}"; do
  DST="${HOOK_DIR}/${hook}"
  if [ -f "$DST" ]; then
    rm "$DST"
    echo "  Removed: ${hook}"
    REMOVED=$((REMOVED + 1))
  else
    echo "  SKIP: ${hook} (not found)"
  fi
done

echo ""
echo "Removed: ${REMOVED} hooks"
echo ""
echo "Don't forget to remove the corresponding entries from ~/.claude/settings.json"
