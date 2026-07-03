#!/usr/bin/env bash
# install-hooks.sh — one-shot installer for doc-sync + conversation-log hooks
# (SKILL §3.13 / §3.15). Bash variant for macOS/Linux/WSL.
set -e
repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Initializing git repo..."
  git init -q
fi
git config core.hooksPath scripts/git-hooks
chmod +x scripts/git-hooks/pre-commit 2>/dev/null || true
git update-index --add --chmod=+x scripts/git-hooks/pre-commit 2>/dev/null || true
chmod +x scripts/*.sh scripts/git-hooks/* 2>/dev/null || true
echo "OK: git pre-commit hook installed (scripts/git-hooks/pre-commit)"
echo "OK: Claude Code PostToolUse hook active   (.claude/settings.json — Section 3.13)"
echo "OK: Claude Code UserPromptSubmit hook active (.claude/settings.json — Section 3.15)"
echo "OK: Cursor doc-sync rule active           (.cursor/rules/sync-docs-on-src-edit.mdc)"
echo ""
echo "From now on:"
echo "  - Edit a file under src/ -> Claude Code reminds you to sync docs/CODE_INDEX.md"
echo "  - Each user prompt       -> auto-appended to docs/CONVERSATION_LOG.md"
echo "  - git commit with src/ changes but no CODE_INDEX update -> BLOCKED"