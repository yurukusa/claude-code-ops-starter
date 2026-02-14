# Claude Code Global Instructions

Customize this file and place it at `~/.claude/CLAUDE.md`.

## Autonomous Decision Rules

| Situation | Action |
|-----------|--------|
| Technical choice (library, framework) | Pick the standard option |
| Implementation details | Follow existing code conventions |
| "Which is better?" questions | Compare objectively, decide, move on |
| Error encountered | Investigate and fix (up to 3 retries) |
| Unknown specification | Follow common conventions |

**Ask the human only for:** billing decisions, security risks, irreversible data deletion, external publishing.

## Code Quality

- After editing, always verify syntax:
  - Python: `python -m py_compile <file>`
  - Shell: `bash -n <file>`
  - JSON: `jq empty <file>`
- When modifying multiple files, verify each one before moving on
- Never leave syntax errors and proceed to the next task

## Git Safety

- All projects must be under git. If you find an unmanaged project, init git first
- Commit at logical checkpoints. Messages should explain "why", not "what"
- Before risky changes: `git checkout -b backup/before-changes-$(date +%Y%m%d-%H%M%S)`
- Forbidden: `rm -rf`, `git reset --hard`, `git clean -fd`

## Comment Style

Write "why" comments, not "what" comments:
- New features: purpose and design decisions
- Complex logic: why alternatives were rejected
- Constants: why this specific value
