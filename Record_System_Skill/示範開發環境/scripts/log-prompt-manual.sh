#!/usr/bin/env bash
# log-prompt-manual.sh — manual conversation-log appender (SKILL §3.16).
# For agent tools without UserPromptSubmit-style hooks (Codex / Gemini CLI / Aider / local LLM).
# Usage: bash scripts/log-prompt-manual.sh "<user prompt text>"
set -u
prompt="${*:-}"
if [ -z "$prompt" ]; then
  echo "Usage: $0 '<user prompt>'" >&2
  exit 2
fi
repo_root=$(cd "$(dirname "$0")/.." && pwd)
log="$repo_root/docs/CONVERSATION_LOG.md"
ts=$(date "+%Y-%m-%d %H:%M:%S")
excerpt=$(printf "%s" "$prompt" | tr -d "\r" | tr "\n" " " | cut -c1-237)
if [ "${#prompt}" -gt 240 ]; then excerpt="${excerpt}..."; fi
if [ ! -f "$log" ]; then
  cat > "$log" <<HDR
# Conversation Log

> Manual / hook-driven. See SKILL §3.15 / §3.16.

## Active Summary
<!-- Rolling. Agent updates at end of every substantive turn. -->

最新方向 / Latest direction:
最近修正 / Recent corrections:
未決問題 / Open questions:
最近批准 / Recent approvals (APPROVED-NNN refs):

## Log Entries
HDR
fi
existing=$(grep -cE "^### .* — CONV-[0-9]{3}" "$log" 2>/dev/null)
[ -z "$existing" ] && existing=0
n=$(printf "%03d" $((existing + 1)))
printf "\n### %s — CONV-%s (manual)\n> %s\n" "$ts" "$n" "$excerpt" >> "$log"
echo "Logged CONV-$n at $ts"