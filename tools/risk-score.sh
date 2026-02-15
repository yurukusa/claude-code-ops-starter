#!/usr/bin/env bash
# risk-score.sh — Claude Code Autonomous Operations Risk Score
# Checks 10 safety items and outputs a risk score with recommendations.
# No dependencies beyond bash and git. No data sent anywhere.
# MIT License — https://github.com/yurukusa/claude-code-ops-starter

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

SCORE=0
MAX_SCORE=0
RESULTS=()

# --- Check function ---
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

# --- Detect project root ---
PROJECT_ROOT="."
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
fi

echo ""
echo "${BOLD}Claude Code Risk Score${RESET}"
echo "Scanning: ${PROJECT_ROOT}"
echo ""

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
HAS_ACCIDENT=1
if git rev-parse --git-dir >/dev/null 2>&1; then
  ACCIDENT_COUNT=$(git reflog 2>/dev/null | grep -cE '(reset.*--hard|clean.*-fd|checkout.*\.)' || true)
  if [[ "$ACCIDENT_COUNT" -gt 0 ]]; then
    check 3 "Git reflog shows ${ACCIDENT_COUNT} risky operation(s)" 1
    HAS_ACCIDENT=0
  else
    check 3 "No risky operations in git reflog" 0
  fi
else
  check 3 "Not a git repository (cannot check reflog)" 1
fi

# --- Output ---
echo "─────────────────────────────────"
for r in "${RESULTS[@]}"; do
  echo -e "  $r"
done
echo "─────────────────────────────────"
echo ""

# Risk level
if [[ $SCORE -eq 0 ]]; then
  LEVEL="${GREEN}LOW${RESET}"
elif [[ $SCORE -le 5 ]]; then
  LEVEL="${YELLOW}MODERATE${RESET}"
elif [[ $SCORE -le 10 ]]; then
  LEVEL="${YELLOW}HIGH${RESET}"
else
  LEVEL="${RED}CRITICAL${RESET}"
fi

echo -e "${BOLD}Risk Score: ${SCORE}/${MAX_SCORE}${RESET} (${LEVEL})"
echo ""

# Recommendations
if [[ $SCORE -gt 0 ]]; then
  echo "${BOLD}Recommendations:${RESET}"
  echo "  → Self-Check (10 items): https://gist.github.com/yurukusa/23b172374e2e32bdff7d85d21e0f19a2"
  echo "  → CLAUDE.md Generator:  https://gist.github.com/yurukusa/9e710dece35d673dd71e678dfa55eaa3"
  echo "  → 4 Free Safety Hooks:  https://github.com/yurukusa/claude-code-ops-starter"
  echo "  → Complete Setup (22 files): https://yurukusa.gumroad.com/l/cc-codex-ops-kit"
  echo ""
fi
