# Fix Bundle Teaser — 2 Free Safety Hooks

Two hooks from the Fix Bundle that address common gaps in autonomous Claude Code operation.

## What's Included

| Hook | Type | Self-Check Item | What It Does |
|------|------|----------------|--------------|
| `session-saver.sh` | Stop | #2: Session state saving | Saves git status, recent files, and pending tasks to `~/session-state.md` when a session ends |
| `git-auto-backup.sh` | PreToolUse (Bash) | #4: Git auto-backup | Creates a backup branch before risky git operations (`merge`, `rebase`, `reset`, `checkout .`, `rm -r`) |

## Install

```bash
git clone https://github.com/yurukusa/claude-code-ops-starter.git
cd claude-code-ops-starter/products/fix-bundle-9-teaser-v1
bash install.sh
```

Then add the hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/session-saver.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/git-auto-backup.sh"
          }
        ]
      }
    ]
  }
}
```

## Uninstall

```bash
bash uninstall.sh
```

Then remove the corresponding entries from `~/.claude/settings.json`.

## What This Does

- **session-saver.sh**: When Claude Code's session ends (Stop event), it captures the current working directory, git branch/status, recently modified files, and pending human tasks. Output goes to `~/session-state.md`. This file is overwritten each session — it's a snapshot, not a log.

- **git-auto-backup.sh**: Before risky git operations, it creates a branch named `backup/auto-YYYYMMDD-HHMMSS`. This is a safety net, not a replacement for proper git workflow. The backup branch is created silently — it won't interrupt your work.

## What This Does NOT Do

- Does not replace proper git practices (commit early, commit often)
- Does not persist session history across multiple sessions (only the last session is saved)
- Does not block dangerous commands — it only creates a recovery point
- Does not monitor context window usage (see the free Ops Starter for that)
- Does not check outbound commands, track errors, or log file changes

## Dependencies

- `bash` (4.0+)
- `git` (for git-auto-backup.sh)
- `jq` (for parsing hook input in git-auto-backup.sh)
- `find` (for session-saver.sh recent files listing)

## The Full Setup

These 2 hooks cover Self-Check items #2 and #4. The remaining items (#7 outbound gate, #8 error RCA, #9 activity logging, and more) are available in the [CC-Codex Ops Kit ($79)](https://yurukusa.gumroad.com/l/cc-codex-ops-kit) — 22 files, 15-minute setup.

## License

MIT — same as the Ops Starter.
