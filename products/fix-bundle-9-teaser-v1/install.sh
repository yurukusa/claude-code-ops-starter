#!/usr/bin/env bash
# install.sh — Install Fix Bundle Teaser hooks
# Copies 2 hooks to ~/.claude/hooks/ without overwriting existing files.
set -euo pipefail

HOOK_DIR="${HOME}/.claude/hooks"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOOK_DIR"

HOOKS=(
  "session-saver.sh"
  "git-auto-backup.sh"
)

echo "Fix Bundle Teaser Installer"
echo "==========================="
echo ""

INSTALLED=0
SKIPPED=0

for hook in "${HOOKS[@]}"; do
  SRC="${SCRIPT_DIR}/hooks/${hook}"
  DST="${HOOK_DIR}/${hook}"

  if [ ! -f "$SRC" ]; then
    echo "  WARN: ${hook} not found in package"
    continue
  fi

  if [ -f "$DST" ]; then
    echo "  SKIP: ${hook} (already exists — won't overwrite)"
    SKIPPED=$((SKIPPED + 1))
  else
    cp "$SRC" "$DST"
    chmod +x "$DST"
    echo "  OK: ${hook} installed"
    INSTALLED=$((INSTALLED + 1))
  fi
done

echo ""
echo "Installed: ${INSTALLED} hooks"
[ "$SKIPPED" -gt 0 ] && echo "Skipped: ${SKIPPED} hooks (already exist)"
echo ""
echo "Next step: Add the hooks to ~/.claude/settings.json"
echo ""
echo "Add this to your settings.json hooks section:"
echo ""
cat << 'SETTINGS'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/session-saver.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/git-auto-backup.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS
echo ""
echo "See README.md for full details."
