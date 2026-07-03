#!/usr/bin/env bash
# log-user-prompt.sh — bash variant of the UserPromptSubmit hook (SKILL §3.15).
# Auto-appends a timestamped excerpt of every user prompt to docs/CONVERSATION_LOG.md.
set -u
payload=$(cat || true)
[ -z "$payload" ] && exit 0
prompt=""
if command -v jq >/dev/null 2>&1; then
  prompt=$(printf "%s" "$payload" | jq -r ".prompt // empty" 2>/dev/null)
else
  # Fallback when jq is missing: best-effort sed extraction of the "prompt" string value
  prompt=$(printf "%s" "$payload" | sed -nE "s/.*\"prompt\"[[:space:]]*:[[:space:]]*\"((\\\\.|[^\"\\\\])*)\".*/\\1/p" | head -1)
fi
[ -z "$prompt" ] && exit 0
repo_root=$(cd "$(dirname "$0")/.." && pwd)
log="$repo_root/docs/CONVERSATION_LOG.md"
ts=$(date "+%Y-%m-%d %H:%M:%S")
excerpt=$(printf "%s" "$prompt" | tr -d "\r" | tr "\n" " " | cut -c1-237)
if [ "${#prompt}" -gt 240 ]; then excerpt="${excerpt}..."; fi
if [ ! -f "$log" ]; then
  cat > "$log" <<HDR
# Conversation Log

> 自動由 Claude Code UserPromptSubmit hook 寫入 (SKILL §3.15)。
> 新接手的 agent 讀這份就能知道使用者對話進行到哪。

## Active Summary
<!-- Rolling. Agent updates this block at the end of every substantive turn. Keep to ~10 lines. -->

最新方向 / Latest direction:
最近修正 / Recent corrections:
未決問題 / Open questions:
最近批准 / Recent approvals (APPROVED-NNN refs):

## Log Entries
HDR
fi
# grep -c exits non-zero on 0 matches even though it still prints "0".
# `||` would then ALSO run printf and we'd get "00" or "0\n0". Capture cleanly:
existing=$(grep -cE "^### .* — CONV-[0-9]{3}" "$log" 2>/dev/null)
[ -z "$existing" ] && existing=0
n=$(printf "%03d" $((existing + 1)))
printf "\n### %s — CONV-%s\n> %s\n" "$ts" "$n" "$excerpt" >> "$log"
exit 0