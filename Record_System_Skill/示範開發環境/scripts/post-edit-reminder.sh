#!/usr/bin/env bash
# post-edit-reminder.sh — bash variant of the Claude Code PostToolUse hook (SKILL §3.13).
# Use this on macOS/Linux/WSL. Reads tool JSON from stdin; emits reminder if path is under src/.
set -u
payload=$(cat || true)
[ -z "$payload" ] && exit 0
file=""
if command -v jq >/dev/null 2>&1; then
  file=$(printf "%s" "$payload" | jq -r ".tool_input.file_path // .tool_input.path // .tool_input.notebook_path // empty" 2>/dev/null)
else
  # Fallback when jq is missing: extract the first matching string value via sed
  file=$(printf "%s" "$payload" | sed -nE "s/.*\"(file_path|path|notebook_path)\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\\2/p" | head -1)
fi
[ -z "$file" ] && exit 0
case "$file" in
  *src/*|src/*) printf "REMINDER (SKILL §3.13): you just modified %s. Before committing: (1) update docs/CODE_INDEX.md bilingual row, (2) append to docs/DEV_LOG.md, (3) run scripts/check-consistency.{sh,ps1}. The git pre-commit hook will block the commit otherwise.\n" "$file" ;;
esac
exit 0