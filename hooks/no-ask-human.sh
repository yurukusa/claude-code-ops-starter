#!/bin/bash
# ================================================================
# no-ask-human.sh — Enforce autonomous decision-making
# ----------------------------------------------------------------
# Purpose:  Block AskUserQuestion tool calls so the AI decides
#           on its own instead of asking "should I continue?"
# Trigger:  PreToolUse (AskUserQuestion)
# Effect:   Returns exit 1 to block the tool call.
#
# When to use: During unattended / overnight sessions where no
# human is available to answer questions.
#
# Exceptions the AI should still ask about:
#   - Billing / charges
#   - Security risks
#   - Irreversible data deletion
#   - Publishing to external services
# ================================================================

echo "BLOCKED: Do not ask the human." >&2
echo "Decision order: 1) Decide yourself  2) Log uncertainty to ~/pending_for_human.md  3) Move to the next task" >&2
echo "AskUserQuestion is only allowed for: billing, security, irreversible deletion, external publishing." >&2
exit 1
