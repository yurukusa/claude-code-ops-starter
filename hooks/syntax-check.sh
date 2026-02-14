#!/bin/bash
# ================================================================
# syntax-check.sh — Auto-verify files after edit/write
# ----------------------------------------------------------------
# Purpose:  Run language-appropriate syntax checks after every
#           Edit or Write tool call. Catches errors immediately.
# Trigger:  PostToolUse (Edit, Write)
# Effect:   Prints OK/ERROR to stderr. Does NOT block (exit 0).
# ================================================================

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
    exit 0
fi

EXT="${FILE_PATH##*.}"

case "$EXT" in
    py)
        if python -m py_compile "$FILE_PATH" 2>&1; then
            echo "Syntax OK: $FILE_PATH"
        else
            echo "SYNTAX ERROR: $FILE_PATH" >&2
        fi
        ;;
    sh|bash)
        if bash -n "$FILE_PATH" 2>&1; then
            echo "Syntax OK: $FILE_PATH"
        else
            echo "SYNTAX ERROR: $FILE_PATH" >&2
        fi
        ;;
    json)
        if jq empty "$FILE_PATH" 2>&1; then
            echo "Syntax OK: $FILE_PATH"
        else
            echo "SYNTAX ERROR: $FILE_PATH" >&2
        fi
        ;;
    *)
        # Skip unsupported file types
        ;;
esac

exit 0
