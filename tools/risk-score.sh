#!/usr/bin/env bash
# risk-score.sh — Claude Code Autonomous Operations Risk Score (FREE)
# Checks 10 safety items and outputs a risk score with recommendations.
# Usage: risk-score.sh          (scan only)
#        risk-score.sh --fix    (scan, install free hooks, re-scan)
# No dependencies beyond bash and git. No data sent anywhere.
# 100% free. Full source: https://github.com/yurukusa/claude-code-ops-starter
# MIT License

set -euo pipefail

# --- Colors (disable if not a terminal) ---
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BOLD='' RESET=''
fi

# --- Parse args ---
FIX_MODE=0
if [[ "${1:-}" == "--fix" ]]; then FIX_MODE=1; fi

# --- Detect project root ---
PROJECT_ROOT="."
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
fi

# --- Check function ---
SCORE=0
MAX_SCORE=0
RESULTS=()

check() {
  local weight=$1
  local label=$2
  local pass=$3  # 0=pass, 1=fail
  MAX_SCORE=$((MAX_SCORE + weight))
  if [[ "$pass" -eq 0 ]]; then
    RESULTS+=("${GREEN}✓${RESET} ${label}")
  else
    SCORE=$((SCORE + weight))
    RESULTS+=("${RED}✗${RESET} ${label} (+${weight})")
  fi
}

# --- Run all checks ---
run_scan() {
  SCORE=0
  MAX_SCORE=0
  RESULTS=()

  # 1. CLAUDE.md existence
  if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]] || [[ -f "${HOME}/.claude/CLAUDE.md" ]]; then
    check 2 "CLAUDE.md found" 0
  else
    check 2 "No CLAUDE.md found" 1
  fi

  # 2. Hooks directory
  HOOKS_DIR="${HOME}/.claude/hooks"
  if [[ -d "$HOOKS_DIR" ]] && [[ -n "$(ls -A "$HOOKS_DIR" 2>/dev/null)" ]]; then
    check 2 "Hooks directory has files" 0
  else
    check 2 "No hooks directory or empty" 1
  fi

  # 3. Dangerous command protection
  HAS_DANGER_HOOK=1
  if [[ -d "$HOOKS_DIR" ]]; then
    while IFS= read -r -d '' f; do
      if grep -ql 'rm.*-rf\|git.*reset.*--hard\|git.*clean.*-f' "$f" 2>/dev/null; then
        HAS_DANGER_HOOK=0
        break
      fi
    done < <(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -o -name '*.bash' 2>/dev/null | tr '\n' '\0')
  fi
  check 3 "Dangerous command protection hook" $HAS_DANGER_HOOK

  # 4. Git auto-backup
  HAS_BACKUP_HOOK=1
  if [[ -d "$HOOKS_DIR" ]]; then
    while IFS= read -r -d '' f; do
      if grep -qlE '(backup|auto-backup|before-changes)' "$f" 2>/dev/null; then
        HAS_BACKUP_HOOK=0
        break
      fi
    done < <(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -o -name '*.bash' 2>/dev/null | tr '\n' '\0')
  fi
  check 2 "Git auto-backup hook" $HAS_BACKUP_HOOK

  # 5. Session state saving
  HAS_SESSION_HOOK=1
  if [[ -d "$HOOKS_DIR" ]]; then
    while IFS= read -r -d '' f; do
      if grep -qlE '(session.state|session-saver|Stop)' "$f" 2>/dev/null; then
        HAS_SESSION_HOOK=0
        break
      fi
    done < <(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -o -name '*.bash' 2>/dev/null | tr '\n' '\0')
  fi
  check 1 "Session state saving" $HAS_SESSION_HOOK

  # 6. External action gate
  HAS_EXT_GATE=1
  if [[ -d "$HOOKS_DIR" ]]; then
    while IFS= read -r -d '' f; do
      if grep -qlE '(external|outbound|consensus|approval|gate)' "$f" 2>/dev/null; then
        HAS_EXT_GATE=0
        break
      fi
    done < <(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -o -name '*.bash' 2>/dev/null | tr '\n' '\0')
  fi
  check 2 "External action gate" $HAS_EXT_GATE

  # 7. Error tracking
  HAS_ERR_TRACK=1
  if [[ -d "$HOOKS_DIR" ]]; then
    while IFS= read -r -d '' f; do
      if grep -qlE '(error.track|err.code|root.cause|error.log)' "$f" 2>/dev/null; then
        HAS_ERR_TRACK=0
        break
      fi
    done < <(find "$HOOKS_DIR" -maxdepth 1 -name '*.sh' -o -name '*.bash' 2>/dev/null | tr '\n' '\0')
  fi
  check 1 "Error tracking" $HAS_ERR_TRACK

  # 8. .gitignore secrets exclusion
  GITIGNORE="${PROJECT_ROOT}/.gitignore"
  if [[ -f "$GITIGNORE" ]]; then
    if grep -qlE '(\.env|credentials|\.secret|\.key|\.pem)' "$GITIGNORE" 2>/dev/null; then
      check 2 "Secrets excluded in .gitignore" 0
    else
      check 2 "No secret patterns in .gitignore" 1
    fi
  else
    check 2 "No .gitignore file" 1
  fi

  # 9. Settings.json permission config
  SETTINGS="${HOME}/.claude/settings.json"
  if [[ -f "$SETTINGS" ]]; then
    check 1 "Claude Code settings.json exists" 0
  else
    SETTINGS_LOCAL="${PROJECT_ROOT}/.claude/settings.json"
    if [[ -f "$SETTINGS_LOCAL" ]]; then
      check 1 "Claude Code settings.json exists (project)" 0
    else
      check 1 "No settings.json found" 1
    fi
  fi

  # 10. Recent git accident traces
  if git rev-parse --git-dir >/dev/null 2>&1; then
    ACCIDENT_COUNT=$(git reflog 2>/dev/null | grep -cE '(reset.*--hard|clean.*-fd|checkout.*\.)' || true)
    if [[ "$ACCIDENT_COUNT" -gt 0 ]]; then
      check 3 "Git reflog shows ${ACCIDENT_COUNT} risky operation(s)" 1
    else
      check 3 "No risky operations in git reflog" 0
    fi
  else
    check 3 "Not a git repository (cannot check reflog)" 1
  fi
}

# --- Get risk level label ---
get_level() {
  local s=$1
  if [[ $s -eq 0 ]]; then
    echo "LOW"
  elif [[ $s -le 5 ]]; then
    echo "MODERATE"
  elif [[ $s -le 10 ]]; then
    echo "HIGH"
  else
    echo "CRITICAL"
  fi
}

get_level_colored() {
  local s=$1
  local level
  level=$(get_level "$s")
  case "$level" in
    LOW)      echo "${GREEN}${level}${RESET}" ;;
    MODERATE) echo "${YELLOW}${level}${RESET}" ;;
    HIGH)     echo "${YELLOW}${level}${RESET}" ;;
    CRITICAL) echo "${RED}${level}${RESET}" ;;
  esac
}

# --- Print scan results ---
print_results() {
  echo "─────────────────────────────────"
  for r in "${RESULTS[@]}"; do
    echo -e "  $r"
  done
  echo "─────────────────────────────────"
  echo ""
  echo -e "${BOLD}Risk Score: ${SCORE}/${MAX_SCORE}${RESET} ($(get_level_colored $SCORE))"
}

# =====================================================
# MAIN
# =====================================================

echo ""
echo "${BOLD}Claude Code Risk Score${RESET}"
echo "Scanning: ${PROJECT_ROOT}"
echo ""

# --- Initial scan ---
run_scan
SCORE_BEFORE=$SCORE

print_results

# --- Fix mode ---
if [[ $FIX_MODE -eq 1 ]] && [[ $SCORE -gt 0 ]]; then
  echo ""
  echo "${BOLD}Installing free safety hooks...${RESET}"
  echo ""

  TMPDIR=$(mktemp -d)
  trap "rm -rf '$TMPDIR'" EXIT

  if git clone --quiet --depth 1 https://github.com/yurukusa/claude-code-ops-starter.git "$TMPDIR" 2>/dev/null; then
    bash "$TMPDIR/install.sh"

    echo ""
    echo "${BOLD}Re-scanning...${RESET}"
    echo ""

    run_scan
    SCORE_AFTER=$SCORE
    print_results

    FIXED=$((SCORE_BEFORE - SCORE_AFTER))
    if [[ $FIXED -gt 0 ]]; then
      echo ""
      echo -e "${GREEN}${BOLD}Improved by ${FIXED} points.${RESET}"
      echo -e "  Before: ${SCORE_BEFORE}/${MAX_SCORE} ($(get_level $SCORE_BEFORE))"
      echo -e "  After:  ${SCORE_AFTER}/${MAX_SCORE} ($(get_level $SCORE_AFTER))"
    fi
  else
    echo "  Could not clone ops-starter repo. Check your network connection."
    echo "  Manual install: https://github.com/yurukusa/claude-code-ops-starter"
  fi

  echo ""
elif [[ $FIX_MODE -eq 1 ]] && [[ $SCORE -eq 0 ]]; then
  echo ""
  echo "${GREEN}Score is already 0 — nothing to fix.${RESET}"
  echo ""
fi

# --- Recommendations ---
if [[ $SCORE -gt 0 ]]; then
  echo ""
  echo "${BOLD}What to do next:${RESET}"
  if [[ $FIX_MODE -eq 0 ]]; then
    echo "  1. Auto-fix (free — installs 4 safety hooks):"
    echo "     bash risk-score.sh --fix"
    echo ""
  fi
  echo "  Free resources:"
  echo "  → 4 Free Safety Hooks:  https://github.com/yurukusa/claude-code-ops-starter"
  echo "  → Self-Check (10 items): https://gist.github.com/yurukusa/23b172374e2e32bdff7d85d21e0f19a2"
  echo "  → CLAUDE.md Generator:  https://gist.github.com/yurukusa/9e710dece35d673dd71e678dfa55eaa3"
  echo ""
  echo "  Want all 10 items covered + context monitor + error tracker?"
  echo "  → CC-Codex Ops Kit (\$9.99): https://yurukusa.gumroad.com/l/cc-codex-ops-kit"
  echo ""
elif [[ $SCORE -eq 0 ]]; then
  echo ""
  echo "${GREEN}${BOLD}All clear!${RESET} Your Claude Code setup is well-protected."
  echo ""
  echo "  Like this tool? Star the repo: https://github.com/yurukusa/claude-code-ops-starter"
  echo ""
fi
