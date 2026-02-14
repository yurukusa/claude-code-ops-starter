# Claude Code Ops Starter

**Production-tested hooks and templates for autonomous Claude Code sessions.**

Stop babysitting your AI. These hooks let Claude Code run autonomously — catching errors, managing context, and making decisions without asking you every 5 minutes.

Built from 200+ hours of real autonomous operation that shipped a [15,000-line game](https://yurukusa.itch.io/azure-flame) with zero manual coding.

## What's Included

| File | What it does |
|------|-------------|
| `hooks/context-monitor.sh` | Tracks context window usage with staged warnings (soft/hard/critical) |
| `hooks/no-ask-human.sh` | Blocks "should I continue?" questions — forces autonomous decisions |
| `hooks/syntax-check.sh` | Auto-runs syntax verification after every file edit (Python, Shell, JSON) |
| `hooks/decision-warn.sh` | Flags destructive commands (`rm -rf`, `git reset --hard`) before execution |
| `templates/CLAUDE.md` | Baseline instructions for autonomous operation |
| `install.sh` | One-command setup |

## Quick Start

```bash
git clone https://github.com/yurukusa/claude-code-ops-starter.git
cd claude-code-ops-starter
bash install.sh
```

Then add the hook configuration to your `~/.claude/settings.json` (the installer prints the exact JSON).

## How the Hooks Work

### Context Monitor
Counts tool calls as a proxy for context window usage. Warns you at 3 thresholds:
- **Soft (80 calls)**: "Consider deferring large tasks"
- **Hard (120 calls)**: "Wrap up and prepare to hand off"
- **Critical (150 calls)**: Auto-generates a checkpoint file for session handoff

### No-Ask-Human
Blocks `AskUserQuestion` tool calls during unattended sessions. Instead of stopping to ask "which approach should I use?", the AI:
1. Decides on its own
2. Logs uncertainty to `~/pending_for_human.md`
3. Moves to the next task

Still allows questions about billing, security, and irreversible operations.

### Syntax Check
Runs after every `Edit` or `Write` tool call:
- Python: `python -m py_compile`
- Shell: `bash -n`
- JSON: `jq empty`

Catches syntax errors immediately instead of discovering them 50 tool calls later.

### Decision Warn
Scans Bash commands for dangerous patterns (`rm -rf`, `git reset --hard`, `DROP TABLE`, etc.) and prints a warning. Doesn't block by default — uncomment one line to enable hard blocking.

## Need More?

This starter kit handles **basic autonomous operation**. If you're running multi-agent setups, overnight sessions, or production workflows, the full kit includes:

- **Multi-agent relay** — Two AI agents (Claude Code + Codex) consulting each other in a loop
- **Stall detection** — Automatic recovery when an agent gets stuck
- **Watchdog process** — Monitors agent health and auto-restarts on crash
- **Task queue system** — YAML-based priority queue with dependency tracking
- **20+ production hooks** — Activity logging, decision recording, error tracking, CDP safety
- **Operational CLAUDE.md** — Battle-tested over 200 hours of real autonomous execution
- **Setup guides** — Step-by-step for multi-agent orchestration

**[Get the full CC-Codex Ops Kit ($79)](https://yurukusa.gumroad.com/l/cc-codex-ops-kit)** — saves 5+ hours/week on debugging stuck loops and recovering crashed sessions.

## Background

This toolkit emerged from a real experiment: a non-engineer using Claude Code to build a complete game ([Azure Flame](https://yurukusa.itch.io/azure-flame), 15,000+ lines of Python) with minimal human intervention. Every hook in this repo solved a real problem encountered during autonomous operation.

Read more about the journey:
- [How Two AIs Consult Each Other While I Sleep](https://zenn.dev/yurukusa/articles/cc-codex-dual-agent-loop) (Zenn)
- [I Spent $200 on AI and Made $2](https://dev.to/yurukusa/i-spent-200-on-ai-and-made-2-what-i-learned-building-a-game-with-claude-code-2b4b) (dev.to)

## License

MIT License. Use it, modify it, share it.

## Contributing

Issues and PRs welcome. If you build a hook that helps your autonomous workflow, please share it.

---

**[@yurukusa_dev](https://x.com/yurukusa_dev)** on X
