# log-user-prompt.ps1 — invoked by Claude Code UserPromptSubmit hook (.claude/settings.json).
# Auto-appends a timestamped excerpt of every user prompt to docs/CONVERSATION_LOG.md.
# Goal: any agent that picks up later can read CONVERSATION_LOG.md and know where the conversation is.
# SKILL §3.15. Silent on parse failures so it never breaks Claude Code.
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
try {
  $payload = [Console]::In.ReadToEnd()
  if (-not $payload) { exit 0 }
  $obj = $payload | ConvertFrom-Json -ErrorAction Stop
  $prompt = $obj.prompt
  if (-not $prompt) { exit 0 }

  $repoRoot = Split-Path $PSScriptRoot -Parent
  $log = Join-Path $repoRoot "docs/CONVERSATION_LOG.md"

  # Truncate prompt to a single-line 240-char excerpt
  $excerpt = ($prompt -replace "\r\n", " ") -replace "\n", " "
  if ($excerpt.Length -gt 240) { $excerpt = $excerpt.Substring(0, 237) + "..." }
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

  # Initialize the log on first run
  if (-not (Test-Path -LiteralPath $log)) {
    $hdr = @"
# Conversation Log

> 自動由 Claude Code UserPromptSubmit hook 寫入 (SKILL §3.15)。
> 新接手的 agent 讀這份就能知道使用者對話進行到哪。
> Auto-appended by the UserPromptSubmit hook. A new agent reads this to know where the user is in the conversation.

## Active Summary
<!-- Rolling. Agent updates this block at the end of every substantive turn. Keep to ~10 lines. -->

最新方向 / Latest direction:
最近修正 / Recent corrections:
未決問題 / Open questions:
最近批准 / Recent approvals (APPROVED-NNN refs):

## Log Entries
"@
    Set-Content -LiteralPath $log -Value $hdr -Encoding utf8
  }

  # Count real CONV-NNN entries (only count entry headings, not template placeholder text)
  $existing = 0
  if (Test-Path -LiteralPath $log) {
    $matches = Select-String -Path $log -Pattern "^### .* — CONV-\d{3}" -ErrorAction SilentlyContinue
    if ($matches) { $existing = $matches.Count }
  }
  $n = "{0:D3}" -f ($existing + 1)
  $entry = "`n### $ts — CONV-$n`n> $excerpt`n"
  Add-Content -LiteralPath $log -Value $entry -Encoding utf8
} catch {
  # silent — never break Claude Code
}
exit 0
