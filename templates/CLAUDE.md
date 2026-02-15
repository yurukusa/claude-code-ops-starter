# Claude Code Global Instructions

Customize this file and place it at `~/.claude/CLAUDE.md` (global) or `<project>/CLAUDE.md` (per-project).

> **Tip:** Use `bash tools/claude-md-generator.sh` to generate a project-specific version interactively.

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
- **Forbidden**: `rm -rf`, `git reset --hard`, `git clean -fd`

## External Action Safety

Before any action that affects systems outside your local environment:
1. **Consensus**: Get approval before pushing code, posting to external services, or modifying shared infrastructure
2. **Factcheck**: Verify claims in any public-facing text — no exaggerated numbers, no unverified statistics
3. **Scope control**: One approval = one action. Don't reuse approvals across different operations

## Error Tracking

- Log errors with context (what failed, why, what was tried)
- After fixing an error, record what worked so the same mistake isn't repeated
- When a pattern of errors emerges, create a prevention rule

## Comment Style

Write "why" comments, not "what" comments:
- New features: purpose and design decisions
- Complex logic: why alternatives were rejected
- Constants: why this specific value
