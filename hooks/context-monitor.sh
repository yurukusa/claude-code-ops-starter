#!/bin/bash
# ================================================================
# context-monitor.sh — Track context window consumption
# ----------------------------------------------------------------
# Purpose:  Count tool calls as a proxy for context usage and warn
#           at configurable thresholds (SOFT → HARD → CRITICAL).
# Trigger:  PostToolUse (fires after every tool call)
# Effect:   Prints staged warnings. At CRITICAL, writes a
#           checkpoint file so you can hand off to a new session.
# ================================================================

COUNTER_FILE="/tmp/cc-context-monitor-count"
STATE_FILE="/tmp/cc-context-monitor-state"
CHECKPOINT_FILE="/tmp/cc-session-checkpoint.md"

# --- Configurable thresholds ---
SOFT_WARNING=80
HARD_WARNING=120
CRITICAL=150

# Increment counter
COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

LAST_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "normal")

# Check every 5 calls to reduce overhead (unless already critical)
if [ $((COUNT % 5)) -ne 0 ] && [ "$LAST_STATE" != "critical" ]; then
    exit 0
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

if [ "$COUNT" -ge "$CRITICAL" ]; then
    if [ "$LAST_STATE" != "critical" ] || [ $((COUNT % 10)) -eq 0 ]; then
        echo "critical" > "$STATE_FILE"

        cat > "$CHECKPOINT_FILE" << EOF
# Session Checkpoint (auto-generated)
**Time**: $TIMESTAMP
**Tool calls**: $COUNT / $CRITICAL (CRITICAL)

## Action Required
1. Save current task state to a status file
2. Start a new session
3. Resume from the checkpoint
EOF

        echo ""
        echo "CRITICAL: Context window nearly exhausted"
        echo "Tool calls: ${COUNT} / limit: ${CRITICAL}"
        echo "--- Save state and start a new session ---"
        echo "Checkpoint written to: $CHECKPOINT_FILE"
    fi
elif [ "$COUNT" -ge "$HARD_WARNING" ]; then
    if [ "$LAST_STATE" != "hard" ]; then
        echo "hard" > "$STATE_FILE"
        echo ""
        echo "WARNING: Context usage high — tool calls ${COUNT}/${CRITICAL}"
        echo "  Wrap up your current task and prepare to hand off."
    fi
elif [ "$COUNT" -ge "$SOFT_WARNING" ]; then
    if [ "$LAST_STATE" != "soft" ]; then
        echo "soft" > "$STATE_FILE"
        echo ""
        echo "NOTE: Context usage rising — tool calls ${COUNT}/${CRITICAL}"
        echo "  ~$((CRITICAL - COUNT)) calls remaining. Consider deferring large tasks."
    fi
fi

exit 0
