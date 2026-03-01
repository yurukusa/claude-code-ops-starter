#!/bin/bash
# cc-solo-watchdog: Keeps Claude Code moving when it goes idle
#
# What it does:
#   Monitors your Claude Code tmux pane for inactivity. When the screen
#   hasn't changed for IDLE_THRESHOLD seconds, it sends a nudge prompt
#   with your current mission focus and task queue — so Claude picks up
#   the next task instead of sitting idle.
#
# Design principles:
#   - Never kills the session (preserves context window)
#   - Sends a nudge via tmux send-keys to wake Claude up
#   - Pulls context from mission.md and task queue
#   - Controlled via a mode file: ~/cc_loop.enabled
#
# Usage:
#   bash cc-solo-watchdog.sh             # run in foreground
#   bash cc-solo-watchdog.sh --bg        # run in background (recommended: inside tmux)
#   bash cc-solo-watchdog.sh --stop      # stop the watchdog
#   bash cc-solo-watchdog.sh --status    # check current state
#
# Requirements:
#   - Claude Code running in a tmux session (default: "cc")
#   - ~/cc_loop.enabled must exist (acts as ON switch)
#
# Quick start:
#   touch ~/cc_loop.enabled
#   bash tools/cc-solo-watchdog.sh --bg

set -uo pipefail

# ============================================================
# Configuration (override via environment variables)
# ============================================================
MODE_FILE="${CC_LOOP_MODE_FILE:-$HOME/cc_loop.enabled}"
TMUX_SESSION="${CC_SOLO_SESSION:-cc}"
STATE_DIR="$HOME/.cache/cc-solo-watchdog"
PID_FILE="$STATE_DIR/watchdog.pid"
LOG_FILE="$STATE_DIR/watchdog.log"
NUDGE_LOG="$STATE_DIR/nudge-history.jsonl"

# Timing
CHECK_INTERVAL=15          # seconds between screen checks
IDLE_THRESHOLD=120         # seconds of no change before sending a nudge
NUDGE_COOLDOWN=300         # seconds to wait before sending another nudge
MAX_NUDGES_PER_HOUR=4      # safety cap: max nudges per hour

# ============================================================
# Argument parsing
# ============================================================
START_BG=0
STOP=0
STATUS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bg) START_BG=1 ;;
        --stop) STOP=1 ;;
        --status) STATUS=1 ;;
        --idle) IDLE_THRESHOLD="$2"; shift ;;
        --session) TMUX_SESSION="$2"; shift ;;
        -h|--help)
            cat << 'EOF'
cc-solo-watchdog: Keeps Claude Code moving when it goes idle

Usage:
  cc-solo-watchdog.sh             run in foreground
  cc-solo-watchdog.sh --bg        run in background (nohup)
  cc-solo-watchdog.sh --stop      stop the watchdog
  cc-solo-watchdog.sh --status    show current state
  cc-solo-watchdog.sh --idle N    set idle threshold in seconds (default: 120)
  cc-solo-watchdog.sh --session S set tmux session name (default: cc)

Mode file:
  touch ~/cc_loop.enabled    # enable the watchdog loop
  rm ~/cc_loop.enabled       # disable (watchdog stops on next check)

Environment variables:
  CC_SOLO_SESSION      tmux session name (default: cc)
  CC_LOOP_MODE_FILE    path to mode file (default: ~/cc_loop.enabled)
EOF
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

mkdir -p "$STATE_DIR"

# ============================================================
# Utilities
# ============================================================
log() {
    local ts
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$ts] $*" >> "$LOG_FILE"
    if [ $START_BG -eq 0 ]; then
        echo "[$ts] $*"
    fi
}

# ============================================================
# --stop
# ============================================================
if [ $STOP -eq 1 ]; then
    if [ -f "$PID_FILE" ]; then
        saved_pid=$(cat "$PID_FILE")
        if kill -0 "$saved_pid" 2>/dev/null; then
            kill "$saved_pid"
            rm -f "$PID_FILE"
            echo "Watchdog stopped (PID $saved_pid)"
        else
            rm -f "$PID_FILE"
            echo "Watchdog was not running (stale PID file removed)"
        fi
    else
        echo "No PID file found — watchdog may not be running"
    fi
    exit 0
fi

# ============================================================
# --status
# ============================================================
if [ $STATUS -eq 1 ]; then
    echo "=== CC Solo Watchdog Status ==="
    echo "Mode file : $([ -f "$MODE_FILE" ] && echo "ENABLED ($MODE_FILE)" || echo "DISABLED (file missing)")"
    echo "Session   : $TMUX_SESSION"
    if [ -f "$PID_FILE" ]; then
        saved_pid=$(cat "$PID_FILE")
        if kill -0 "$saved_pid" 2>/dev/null; then
            echo "Process   : RUNNING (PID $saved_pid)"
        else
            echo "Process   : DEAD (stale PID $saved_pid)"
        fi
    else
        echo "Process   : NOT RUNNING"
    fi
    if [ -f "$NUDGE_LOG" ]; then
        echo "Last nudge: $(tail -1 "$NUDGE_LOG" 2>/dev/null || echo none)"
        count_1h=$(awk -v cutoff="$(date -d '1 hour ago' +%s 2>/dev/null || echo 0)" \
            'BEGIN{c=0} /"epoch":/{match($0,/"epoch":([0-9]+)/,a); match($0,/"type":"nudge"/); if(a[1]+0>cutoff+0 && RSTART>0) c++} END{print c}' \
            "$NUDGE_LOG" 2>/dev/null || echo "?")
        echo "Nudges/1h : $count_1h / $MAX_NUDGES_PER_HOUR"
    else
        echo "No nudge history yet"
    fi
    exit 0
fi

# ============================================================
# --bg: restart in background
# ============================================================
if [ $START_BG -eq 1 ]; then
    pkill -f "cc-solo-watchdog.sh" 2>/dev/null || true
    sleep 0.5
    nohup "$0" > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    echo "Watchdog started in background (PID $!)"
    echo "Log: $LOG_FILE"
    exit 0
fi

# ============================================================
# Prevent duplicate instances
# ============================================================
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if [ "$old_pid" != "$$" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo "Watchdog already running (PID $old_pid). Use --stop first."
        exit 1
    fi
fi
echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"; log "Watchdog terminated."; exit 0' EXIT INT TERM

log "=== CC Solo Watchdog starting ==="
log "IDLE_THRESHOLD=${IDLE_THRESHOLD}s  NUDGE_COOLDOWN=${NUDGE_COOLDOWN}s  SESSION=$TMUX_SESSION"

# ============================================================
# Get next task from queue (optional integration)
# ============================================================
get_next_task() {
    # Supports task-queue CLI — install from cc-ops-kit or use your own
    if command -v task-queue >/dev/null 2>&1; then
        task-queue next 2>/dev/null | head -5
    # Fallback: read first few lines from task queue file
    elif [ -f "$HOME/tasks/queue.md" ]; then
        grep -E "^\s*[-*]\s*\[[ ]\]" "$HOME/tasks/queue.md" | head -3
    elif [ -f "$HOME/task-queue.yaml" ]; then
        grep -E "^\s*-\s*(title|task):" "$HOME/task-queue.yaml" | head -3
    else
        echo "(no task queue found — create ~/tasks/queue.md or install task-queue CLI)"
    fi
}

# ============================================================
# Build nudge message
# ============================================================
build_nudge() {
    local next_task
    next_task=$(get_next_task)

    # Pull current focus from mission.md (looks for a "## Now" or similar section)
    local focus=""
    local mission_file=""
    for f in "$HOME/ops/mission.md" "$HOME/mission.md" "$HOME/MISSION.md"; do
        [ -f "$f" ] && mission_file="$f" && break
    done

    if [ -n "$mission_file" ]; then
        # Try to find a "Now" / "Focus" / "Current" section
        focus=$(awk '
            /^##[[:space:]]*(Now|Focus|Current|Priority|Today)/{ found=1; next }
            found && /^##[[:space:]]/ { exit }
            found { print }
        ' "$mission_file" | grep -E "^\s*[-*●]|^\s*[0-9]+\." | head -5)

        # Fallback: first checklist items
        if [ -z "$focus" ]; then
            focus=$(head -50 "$mission_file" | grep -E "\[[ x]\]|^\s*[-*]\s" | head -6)
        fi
    fi

    local today
    today=$(date '+%Y-%m-%d %H:%M')

    cat << EOF
[idle ${IDLE_THRESHOLD}s detected / ${today}]

▶ Decision tree — check in order
1. Any content scheduled for today or earlier?  → publish it
2. Any finished but unshipped work?             → ship it
3. Top item in your task queue?                 → work on it
4. Blocked 3+ times on one thing?              → log it in pending_for_human.md, move on

▶ Next task
${next_task:-(task queue empty — pick the highest-value thing you can do right now)}

▶ Mission focus
${focus:-(no mission.md found — create ~/ops/mission.md or ~/mission.md)}

▶ Before you act
- "ready to publish" ≠ "should publish now" — check scheduled dates first
- Would this output meet your own quality bar?
EOF
}

# ============================================================
# Send nudge via tmux
# ============================================================
send_nudge() {
    local message="$1"

    # Rate limiting: count nudge events in the last hour
    if [ -f "$NUDGE_LOG" ]; then
        local cutoff
        cutoff=$(date -d "1 hour ago" +%s 2>/dev/null || echo 0)
        local count
        count=$(awk -v c="$cutoff" '
            BEGIN{n=0}
            /"epoch":/{
                match($0,/"epoch":([0-9]+)/,a)
                match($0,/"type":"nudge"/)
                if(a[1]+0>c+0 && RSTART>0) n++
            }
            END{print n}
        ' "$NUDGE_LOG" 2>/dev/null || echo 0)
        if [ "$count" -ge "$MAX_NUDGES_PER_HOUR" ]; then
            log "RATE_LIMIT: ${count}/${MAX_NUDGES_PER_HOUR} nudges in last hour — skipping"
            return 1
        fi
    fi

    # Clear any partial input, then send the full message
    tmux send-keys -t "$TMUX_SESSION" Escape 2>/dev/null
    sleep 0.3
    tmux send-keys -l -t "$TMUX_SESSION" "$message"
    sleep 0.3
    tmux send-keys -t "$TMUX_SESSION" Enter

    # Log the nudge event
    local epoch ts
    epoch=$(date +%s)
    ts=$(date '+%Y-%m-%dT%H:%M:%S%z')
    echo "{\"epoch\":${epoch},\"time\":\"${ts}\",\"type\":\"nudge\"}" >> "$NUDGE_LOG"

    log "Nudge sent ($(echo "$message" | wc -c) bytes)"
    return 0
}

# ============================================================
# Main loop
# ============================================================
idle_since=0
prev_hash=""
last_nudge_epoch=0

log "Watching tmux session '$TMUX_SESSION' — idle threshold: ${IDLE_THRESHOLD}s"
log "Mode file: $MODE_FILE"

while true; do
    sleep "$CHECK_INTERVAL"

    # Stop if mode file is removed
    if [ ! -f "$MODE_FILE" ]; then
        log "Mode file removed — watchdog stopping"
        break
    fi

    # Check tmux session exists
    if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        log "WARN: tmux session '$TMUX_SESSION' not found — waiting"
        idle_since=0
        continue
    fi

    # Check that a claude process is actually running in the pane
    pane_pid=$(tmux list-panes -t "$TMUX_SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
    if [ -z "$pane_pid" ]; then
        log "WARN: could not get pane PID"
        continue
    fi
    if ! pgrep -P "$pane_pid" -f "claude" >/dev/null 2>&1; then
        log "INFO: no claude process found in pane — skipping"
        idle_since=0
        continue
    fi

    # Detect screen changes via pane content hash
    current_hash=$(tmux capture-pane -t "$TMUX_SESSION" -p 2>/dev/null | md5sum | cut -d' ' -f1)

    if [ -n "$prev_hash" ] && [ "$current_hash" = "$prev_hash" ]; then
        # Screen unchanged
        if [ $idle_since -eq 0 ]; then
            idle_since=$(date +%s)
            log "Idle timer started"
        else
            now=$(date +%s)
            elapsed=$((now - idle_since))

            if [ $elapsed -ge "$IDLE_THRESHOLD" ]; then
                cooldown_elapsed=$((now - last_nudge_epoch))
                if [ $cooldown_elapsed -ge "$NUDGE_COOLDOWN" ]; then
                    log "Idle for ${elapsed}s — sending nudge"
                    nudge_msg=$(build_nudge)
                    if send_nudge "$nudge_msg"; then
                        last_nudge_epoch=$(date +%s)
                        idle_since=0
                    fi
                else
                    log "Idle ${elapsed}s — cooldown active (${cooldown_elapsed}/${NUDGE_COOLDOWN}s)"
                fi
            fi
        fi
    else
        # Screen changed — Claude is working
        if [ $idle_since -ne 0 ]; then
            recovered=$(($(date +%s) - idle_since))
            log "Activity detected after ${recovered}s idle — timer reset"
        fi
        idle_since=0
        prev_hash="$current_hash"
    fi
done

log "=== CC Solo Watchdog stopped ==="
