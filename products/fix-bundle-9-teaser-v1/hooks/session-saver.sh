#!/usr/bin/env bash
# session-saver.sh — Save session state on Stop (Self-Check #2)
# Hook type: Stop
# Saves current working context so the next session can resume quickly.
#
# Output: ~/session-state.md (overwritten each time)
# Part of Fix Bundle Teaser — https://github.com/yurukusa/claude-code-ops-starter

set -euo pipefail

STATE_FILE="${HOME}/session-state.md"

{
  echo "# Session State — $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""

  # Current directory
  echo "## Working Directory"
  echo "\`$(pwd)\`"
  echo ""

  # Git status (if in a repo)
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "## Git Status"
    echo "\`\`\`"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'detached')"
    echo "Last commit: $(git log -1 --oneline 2>/dev/null || echo 'none')"
    CHANGED=$(git status --porcelain 2>/dev/null | wc -l)
    echo "Uncommitted changes: ${CHANGED} files"
    echo "\`\`\`"
    echo ""
  fi

  # Recent file changes (last 10 modified files)
  echo "## Recently Modified Files"
  echo "\`\`\`"
  find . -maxdepth 3 -type f -mmin -60 -not -path './.git/*' 2>/dev/null | head -10 || echo "none"
  echo "\`\`\`"
  echo ""

  # Pending tasks (if pending_for_human.md exists)
  if [ -f "${HOME}/pending_for_human.md" ]; then
    echo "## Pending for Human"
    head -20 "${HOME}/pending_for_human.md"
    echo ""
  fi

  echo "---"
  echo "*Saved by session-saver.sh (Fix Bundle Teaser)*"
} > "$STATE_FILE"

echo "Session state saved to ${STATE_FILE}"
