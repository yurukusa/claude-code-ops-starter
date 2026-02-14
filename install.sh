#!/bin/bash
# ================================================================
# Claude Code Ops Starter — One-command installer
# ================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$HOME/.claude/hooks"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo "=== Claude Code Ops Starter — Installer ==="
echo ""

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install hooks
HOOKS=(
    "context-monitor.sh"
    "no-ask-human.sh"
    "syntax-check.sh"
    "decision-warn.sh"
)

echo "Installing hooks to $HOOKS_DIR ..."
for hook in "${HOOKS[@]}"; do
    src="$SCRIPT_DIR/hooks/$hook"
    dst="$HOOKS_DIR/$hook"
    if [ -f "$dst" ]; then
        echo "  [skip] $hook (already exists — rename existing file to install)"
    else
        cp "$src" "$dst"
        chmod +x "$dst"
        echo "  [ok]   $hook"
    fi
done

# Install CLAUDE.md template
echo ""
if [ -f "$CLAUDE_MD" ]; then
    echo "CLAUDE.md already exists at $CLAUDE_MD"
    echo "  Template saved to: $SCRIPT_DIR/templates/CLAUDE.md"
    echo "  Review and merge manually if you want."
else
    cp "$SCRIPT_DIR/templates/CLAUDE.md" "$CLAUDE_MD"
    echo "CLAUDE.md installed to $CLAUDE_MD"
fi

# Configure hooks in settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
echo ""
echo "Hook configuration:"
echo "  Add these to your $SETTINGS_FILE under \"hooks\":"
echo ""
cat << 'SETTINGS'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "AskUserQuestion",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/no-ask-human.sh"}]
      },
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/decision-warn.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/syntax-check.sh"}]
      },
      {
        "matcher": "",
        "hooks": [{"type": "command", "command": "~/.claude/hooks/context-monitor.sh"}]
      }
    ]
  }
}
SETTINGS

echo ""
echo "=== Installation complete ==="
echo ""
echo "What you got:"
echo "  - context-monitor.sh  : Tracks context window usage with staged warnings"
echo "  - no-ask-human.sh     : Blocks AI from asking you questions (autonomous mode)"
echo "  - syntax-check.sh     : Auto-verifies code after every edit"
echo "  - decision-warn.sh    : Flags destructive commands before execution"
echo "  - CLAUDE.md template  : Baseline instructions for autonomous operation"
echo ""
echo "Want multi-agent orchestration, stall detection, watchdog,"
echo "task queue, and 20+ production hooks?"
echo ""
echo "  Get the full Ops Kit: https://yurukusa.gumroad.com/l/cc-codex-ops-kit"
echo ""
