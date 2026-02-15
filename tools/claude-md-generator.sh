#!/usr/bin/env bash
# claude-md-generator.sh — Interactive CLAUDE.md generator for Claude Code
# Generates a project-specific CLAUDE.md with safety rules built in.
# Part of claude-code-ops-starter (https://github.com/yurukusa/claude-code-ops-starter)
#
# Usage:
#   bash claude-md-generator.sh              # Interactive mode
#   bash claude-md-generator.sh --defaults   # Non-interactive with sensible defaults
#   bash claude-md-generator.sh --help       # Show help

set -euo pipefail

VERSION="1.0.0"
OUTPUT_FILE=""
USE_DEFAULTS=false

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  BOLD='\033[1m'
  GREEN='\033[32m'
  CYAN='\033[36m'
  YELLOW='\033[33m'
  RESET='\033[0m'
else
  BOLD='' GREEN='' CYAN='' YELLOW='' RESET=''
fi

usage() {
  cat <<'EOF'
claude-md-generator — Generate a CLAUDE.md for your project

USAGE
  bash claude-md-generator.sh [OPTIONS]

OPTIONS
  --defaults      Skip questions, use sensible defaults
  --output PATH   Write to PATH instead of ./CLAUDE.md
  --help          Show this help
  --version       Show version

EXAMPLES
  # Interactive — answer 8 questions, get a tailored CLAUDE.md
  bash claude-md-generator.sh

  # Quick start with defaults
  bash claude-md-generator.sh --defaults --output ~/.claude/CLAUDE.md
EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --defaults) USE_DEFAULTS=true; shift ;;
    --output)   OUTPUT_FILE="$2"; shift 2 ;;
    --help|-h)  usage ;;
    --version)  echo "claude-md-generator v${VERSION}"; exit 0 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[ -z "$OUTPUT_FILE" ] && OUTPUT_FILE="./CLAUDE.md"

# ── Helpers ──────────────────────────────────────────────────────────

ask() {
  local prompt="$1" default="$2" var_name="$3"
  if $USE_DEFAULTS; then
    eval "$var_name=\"$default\""
    return
  fi
  printf "${CYAN}%s${RESET} [${YELLOW}%s${RESET}]: " "$prompt" "$default"
  read -r answer
  eval "$var_name=\"${answer:-$default}\""
}

ask_choice() {
  local prompt="$1" default="$2" var_name="$3"
  shift 3
  local options=("$@")

  if $USE_DEFAULTS; then
    eval "$var_name=\"$default\""
    return
  fi

  printf "\n${BOLD}%s${RESET}\n" "$prompt"
  local i=1
  for opt in "${options[@]}"; do
    if [ "$opt" = "$default" ]; then
      printf "  ${GREEN}%d) %s (default)${RESET}\n" "$i" "$opt"
    else
      printf "  %d) %s\n" "$i" "$opt"
    fi
    ((i++))
  done
  printf "Choice [${YELLOW}1${RESET}]: "
  read -r choice
  choice="${choice:-1}"
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
    eval "$var_name=\"${options[$((choice-1))]}\""
  else
    eval "$var_name=\"$default\""
  fi
}

ask_yn() {
  local prompt="$1" default="$2" var_name="$3"
  if $USE_DEFAULTS; then
    eval "$var_name=\"$default\""
    return
  fi
  printf "${CYAN}%s${RESET} [${YELLOW}%s${RESET}]: " "$prompt" "$default"
  read -r answer
  answer="${answer:-$default}"
  case "$answer" in
    [Yy]*) eval "$var_name=yes" ;;
    *)     eval "$var_name=no" ;;
  esac
}

# ── Questions ────────────────────────────────────────────────────────

if ! $USE_DEFAULTS; then
  printf "\n${BOLD}🔧 CLAUDE.md Generator v${VERSION}${RESET}\n"
  printf "Answer 8 questions to generate a project-specific CLAUDE.md.\n"
  printf "Press Enter to accept the default value shown in [brackets].\n\n"
fi

ask "Project name" "my-project" PROJECT_NAME
ask_choice "Primary language" "Python" LANGUAGE \
  "Python" "JavaScript/TypeScript" "Go" "Rust" "Java" "Shell" "Other"
ask "Framework (or 'none')" "none" FRAMEWORK
ask "Test command" "pytest" TEST_CMD
ask "Lint/format command (or 'none')" "none" LINT_CMD

ask_yn "Enable safety gates (consensus/factcheck for external actions)?" "yes" ENABLE_GATES
ask_yn "Enable error tracking (err-tracker/proof-log)?" "yes" ENABLE_TRACKING
ask_yn "Enable dangerous command blocking?" "yes" ENABLE_DANGER_BLOCK

# ── Syntax check command by language ─────────────────────────────────

case "$LANGUAGE" in
  "Python")
    SYNTAX_CHECK='- Python: `python -m py_compile <file>`' ;;
  "JavaScript/TypeScript")
    SYNTAX_CHECK='- JavaScript/TypeScript: `npx tsc --noEmit` or `node --check <file>`' ;;
  "Go")
    SYNTAX_CHECK='- Go: `go vet ./...`' ;;
  "Rust")
    SYNTAX_CHECK='- Rust: `cargo check`' ;;
  "Java")
    SYNTAX_CHECK='- Java: `javac -d /tmp <file>`' ;;
  "Shell")
    SYNTAX_CHECK='- Shell: `bash -n <file>` or `shellcheck <file>`' ;;
  *)
    SYNTAX_CHECK='- Verify syntax after every edit using your language'"'"'s checker' ;;
esac

# ── Generate CLAUDE.md ───────────────────────────────────────────────

{
cat <<HEADER
# ${PROJECT_NAME} — Claude Code Instructions

## Autonomous Decision Rules

| Situation | Action |
|-----------|--------|
| Technical choice (library, framework) | Pick the standard option |
| Implementation details | Follow existing code conventions |
| "Which is better?" questions | Compare objectively, decide, move on |
| Error encountered | Investigate and fix (up to 3 retries) |
| Unknown specification | Follow common conventions |

**Ask the human only for:** billing decisions, security risks, irreversible data deletion, external publishing.

HEADER

# Framework section
if [ "$FRAMEWORK" != "none" ]; then
  cat <<FRAMEWORK_SECTION
## Framework

This project uses **${FRAMEWORK}**. Follow its conventions and best practices.

FRAMEWORK_SECTION
fi

# Code quality
cat <<QUALITY
## Code Quality

After editing, always verify syntax:
${SYNTAX_CHECK}
- When modifying multiple files, verify each one before moving on
- Never leave syntax errors and proceed to the next task
QUALITY

# Test command
cat <<TESTING

## Testing

Run tests with: \`${TEST_CMD}\`
- Run tests after significant changes to verify nothing is broken
- Fix failing tests before moving to the next task
TESTING

# Lint command
if [ "$LINT_CMD" != "none" ]; then
  cat <<LINTING

## Linting

Run lint/format with: \`${LINT_CMD}\`
- Fix lint errors before committing
LINTING
fi

# Git safety
cat <<GIT

## Git Safety

- All projects must be under git. If unmanaged, init git first
- Commit at logical checkpoints. Messages explain "why", not "what"
- Before risky changes: \`git checkout -b backup/before-changes-\$(date +%Y%m%d-%H%M%S)\`
- **Forbidden**: \`rm -rf\`, \`git reset --hard\`, \`git clean -fd\`
GIT

# Dangerous command blocking
if [ "$ENABLE_DANGER_BLOCK" = "yes" ]; then
  cat <<DANGER

## Dangerous Command Protection

The following commands are blocked or require explicit confirmation:
- \`rm -rf\` — recursive delete
- \`git reset --hard\` — discard all changes
- \`git push --force\` — overwrite remote history
- \`DROP TABLE\` / \`DELETE FROM\` — destructive database operations
- \`git clean -fd\` — delete untracked files
DANGER
fi

# Safety gates
if [ "$ENABLE_GATES" = "yes" ]; then
  cat <<GATES

## External Action Safety

Before any action that affects systems outside your local environment:
1. **Consensus**: Get approval before pushing code, posting to external services, or modifying shared infrastructure
2. **Factcheck**: Verify claims in any public-facing text — no exaggerated numbers, no unverified statistics
3. **Scope control**: One approval = one action. Don't reuse approvals across different operations

Actions that require approval:
- \`git push\`
- API calls that create/modify/delete external resources
- Posting to social media, forums, or package registries
- Sending emails or messages to external services
GATES
fi

# Error tracking
if [ "$ENABLE_TRACKING" = "yes" ]; then
  cat <<TRACKING

## Error Tracking

- Log errors with context (what failed, why, what was tried)
- After fixing an error, record what worked so the same mistake isn't repeated
- Track proof of work: what was done, when, and the outcome
- When a pattern of errors emerges, create a prevention rule
TRACKING
fi

# Comment style
cat <<COMMENTS

## Comment Style

Write "why" comments, not "what" comments:
- New features: purpose and design decisions
- Complex logic: why alternatives were rejected
- Constants: why this specific value
COMMENTS

# Footer
cat <<FOOTER

---
*Generated by [claude-md-generator](https://github.com/yurukusa/claude-code-ops-starter) v${VERSION}*
FOOTER

} > "$OUTPUT_FILE"

# ── Done ─────────────────────────────────────────────────────────────

printf "\n${GREEN}✓${RESET} Generated ${BOLD}%s${RESET}\n" "$OUTPUT_FILE"
printf "  Next steps:\n"
printf "  1. Review and customize the generated file\n"
printf "  2. Place it at: ${CYAN}~/.claude/CLAUDE.md${RESET} (global) or ${CYAN}<project>/CLAUDE.md${RESET} (per-project)\n"
printf "  3. For production hooks: ${CYAN}https://github.com/yurukusa/claude-code-ops-starter${RESET}\n"
