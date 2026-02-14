#!/bin/bash
# ================================================================
# decision-warn.sh — Flag risky decisions before execution
# ----------------------------------------------------------------
# Purpose:  Detect potentially dangerous Bash commands
#           (rm -rf, git reset --hard, etc.) and print a warning.
# Trigger:  PreToolUse (Bash)
# Effect:   Prints warning but does NOT block (exit 0).
#           Override with exit 1 if you want hard blocking.
# ================================================================

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# List of patterns that warrant a warning
RISKY_PATTERNS=(
    "rm -rf"
    "git reset --hard"
    "git clean -fd"
    "git push --force"
    "git push -f"
    "drop table"
    "DROP TABLE"
    "truncate"
    "TRUNCATE"
)

for pattern in "${RISKY_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qi "$pattern"; then
        echo "" >&2
        echo "WARNING: Potentially destructive command detected" >&2
        echo "  Pattern: $pattern" >&2
        echo "  Command: $COMMAND" >&2
        echo "  Consider creating a backup first." >&2
        echo "" >&2
        # exit 1  # Uncomment to hard-block instead of warn
        break
    fi
done

exit 0
