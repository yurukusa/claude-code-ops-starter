# SkillStack Listing Draft — Claude Code Ops Kit

## Title
Claude Code Ops Kit — Production Safety in 15 Minutes

## Price
$19

## Short Description (for card/preview)
10 production hooks + 5 templates + 3 exclusive tools. One-command install for autonomous Claude Code safety. Built from 160+ hours of real autonomous operation.

## Full Description

### The Problem
Autonomous Claude Code sessions can delete files, push to wrong branches, and burn context without warning. The free hooks repo gives you parts — you read docs, configure each hook, wire up settings.json. Takes ~45 min if nothing goes wrong.

### The Solution
The Ops Kit gives you the assembled package. Run `install.sh`, pick a preset, done in 15 minutes.

### What's Included

**10 Production Hooks:**
- context-monitor — graduated context window warnings (CAUTION → EMERGENCY)
- syntax-check — automatic validation after every edit
- branch-guard — blocks accidental push to main/master
- decision-warn — alerts on edits to monitored paths
- error-gate — blocks publishing when unresolved errors exist
- no-ask-human — enforces autonomous decision-making
- activity-logger — JSONL audit trail of all file changes
- cdp-safety-check — validates browser automation port
- proof-log-session — daily operation log
- session-start-marker — marks session boundaries

**6 Templates:**
- CLAUDE.md (baseline) — production-ready instructions
- CLAUDE-autonomous.md — full autonomous operation config
- DoD checklists — verification before "done"
- task-queue.yaml — structured task management
- mission.md — session state persistence
- LESSONS.md — self-improvement tracking

**3 Exclusive Tools (not in the free repo):**
- cc-solo-watchdog — detects idle/stuck sessions
- claude-md-generator — interactive 8-question CLAUDE.md setup
- risk-score — 10-item safety scan with actionable fixes

**3 Settings Presets:**
- Minimal — basic safety for supervised sessions
- Standard — balanced hooks for daily use
- Autonomous — full safety net for unattended operation

### One-Command Install
```bash
bash install.sh
```
Copies hooks, templates, and tools. Sets up settings.json with your chosen preset. Done.

## Tags
claude-code, hooks, safety, autonomous, production, templates, CLAUDE.md

## Category
Hooks & Configuration
