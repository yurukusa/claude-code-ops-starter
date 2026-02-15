#!/usr/bin/env bash
# git-auto-backup.sh — Create backup branch before risky operations (Self-Check #4)
# Hook type: PreToolUse (Bash)
# Creates a backup branch when git-modifying or bulk-change commands are detected.
#
# Part of Fix Bundle Teaser — https://github.com/yurukusa/claude-code-ops-starter

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract the command
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$CMD" ] && exit 0

# Only trigger on git-modifying or bulk-change commands
NEEDS_BACKUP=false

if echo "$CMD" | grep -qE '(git (merge|rebase|cherry-pick|reset|checkout \.|restore \.))|rm -r|find .* -delete'; then
  NEEDS_BACKUP=true
fi

if [ "$NEEDS_BACKUP" = "true" ] && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  BRANCH="backup/auto-$(date +%Y%m%d-%H%M%S)"
  git branch "$BRANCH" 2>/dev/null && echo "Backup branch created: $BRANCH" || true
fi

exit 0
