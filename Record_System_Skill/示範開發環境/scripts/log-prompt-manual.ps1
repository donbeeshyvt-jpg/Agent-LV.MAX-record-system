param([Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)][string[]]$Prompt)
# log-prompt-manual.ps1 — manual conversation-log appender (SKILL §3.16).
# For agent tools without a UserPromptSubmit-style hook (Codex / Gemini CLI / Aider / local LLM).
# Usage: pwsh scripts/log-prompt-manual.ps1 "<user prompt text>"
# (Claude Code uses scripts/log-user-prompt.ps1 automatically via UserPromptSubmit hook.)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$promptText = ($Prompt -join " ").Trim()
if (-not $promptText) { Write-Host "Usage: log-prompt-manual.ps1 '<user prompt>'"; exit 2 }
$repoRoot = Split-Path $PSScriptRoot -Parent
$log = Join-Path $repoRoot "docs/CONVERSATION_LOG.md"
$excerpt = ($promptText -replace "\r\n", " ") -replace "\n", " "
if ($excerpt.Length -gt 240) { $excerpt = $excerpt.Substring(0, 237) + "..." }
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if (-not (Test-Path -LiteralPath $log)) {
  $hdr = @"
# Conversation Log

> Manual / hook-driven. See SKILL §3.15 / §3.16.

## Active Summary
<!-- Rolling. Agent updates at end of every substantive turn. -->

最新方向 / Latest direction:
最近修正 / Recent corrections:
未決問題 / Open questions:
最近批准 / Recent approvals (APPROVED-NNN refs):

## Log Entries
"@
  Set-Content -LiteralPath $log -Value $hdr -Encoding utf8
}
$existing = 0
$matches = Select-String -Path $log -Pattern "^### .* — CONV-\d{3}" -ErrorAction SilentlyContinue
if ($matches) { $existing = $matches.Count }
$n = "{0:D3}" -f ($existing + 1)
$entry = "`n### $ts — CONV-$n (manual)`n> $excerpt`n"
Add-Content -LiteralPath $log -Value $entry -Encoding utf8
Write-Host ("Logged CONV-" + $n + " at " + $ts) -ForegroundColor Green
