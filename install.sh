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
    "activity-logger.sh"
    "branch-guard.sh"
    "error-gate.sh"
    "cdp-safety-check.sh"
    "proof-log-session.sh"
    "session-start-marker.sh"
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
sed 's|/path/to/hooks|~/.claude/hooks|g' "$SCRIPT_DIR/examples/settings.json"

echo ""
echo "=== Installation complete ==="
echo ""
echo "What you got:"
echo "  10 hooks:"
echo "    context-monitor.sh     : Context window usage warnings"
echo "    no-ask-human.sh        : Blocks AI from asking you questions"
echo "    syntax-check.sh        : Auto-verifies code after every edit"
echo "    decision-warn.sh       : Flags destructive commands"
echo "    activity-logger.sh     : Logs every tool call for audit"
echo "    branch-guard.sh        : Prevents commits to main/master"
echo "    error-gate.sh          : Blocks continuation after repeated errors"
echo "    cdp-safety-check.sh    : Validates CDP browser targets"
echo "    proof-log-session.sh   : Auto-generates session proof logs"
echo "    session-start-marker.sh: Stamps session metadata on startup"
echo ""
echo "  3 tools:"
echo "    cc-solo-watchdog.sh    : Idle detector — nudges Claude when it goes quiet"
echo "    claude-md-generator.sh : Interactive CLAUDE.md generator"
echo "    risk-score.sh          : Safety score checker (10 items)"
echo ""
echo "  6 templates + 3 config examples"
echo ""
echo "=== Optional: Enable the Autonomous Loop ==="
echo ""
echo "cc-solo-watchdog keeps Claude working while you're away."
echo ""
echo "  # Start once (inside a tmux session named 'cc'):"
echo "  touch ~/cc_loop.enabled"
echo "  bash $(realpath "$SCRIPT_DIR/tools/cc-solo-watchdog.sh") --bg"
echo ""
echo "  # Stop:"
echo "  bash $(realpath "$SCRIPT_DIR/tools/cc-solo-watchdog.sh") --stop"
echo "  # or: rm ~/cc_loop.enabled"
echo ""
