# install-hooks.ps1 — one-shot installer for the doc-sync + conversation-log hooks
# (SKILL §3.13 / §3.15). Idempotent: safe to run repeatedly.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

# Robust git detection — works for worktrees, submodules, and regular repos.
$gitDir = $null
try { $gitDir = & git rev-parse --git-dir 2>$null } catch { $gitDir = $null }
if (-not $gitDir) {
  Write-Host "Initializing git repo..." -ForegroundColor Cyan
  try { git init -q } catch {
    Write-Host "ERROR: git not on PATH or git init failed." -ForegroundColor Red
    exit 1
  }
}

# 1. Wire the pre-commit hook (suppress stderr noise from git LF/CRLF warnings)
$ErrorActionPreference = "Continue"
& git config core.hooksPath scripts/git-hooks 2>$null
# Mark the bash hook executable in git'+'s index so non-Windows clones get it active.
if (Test-Path "scripts/git-hooks/pre-commit") {
  & git update-index --add --chmod=+x scripts/git-hooks/pre-commit 2>$null | Out-Null
}
$ErrorActionPreference = "Stop"
Write-Host "OK: git pre-commit hook installed (scripts/git-hooks/pre-commit)" -ForegroundColor Green

Write-Host "OK: Claude Code PostToolUse hook active   (.claude/settings.json — Section 3.13)" -ForegroundColor Green
Write-Host "OK: Claude Code UserPromptSubmit hook active (.claude/settings.json — Section 3.15, auto-appends docs/CONVERSATION_LOG.md)" -ForegroundColor Green
Write-Host "OK: Cursor doc-sync rule active           (.cursor/rules/sync-docs-on-src-edit.mdc)" -ForegroundColor Green
Write-Host ""
Write-Host "From now on:" -ForegroundColor Yellow
Write-Host "  - Edit a file under src/  -> Claude Code / Cursor reminds you to sync docs/CODE_INDEX.md" -ForegroundColor Yellow
Write-Host "  - Each user prompt        -> auto-appended to docs/CONVERSATION_LOG.md" -ForegroundColor Yellow
Write-Host "  - git commit with src/ changes but no CODE_INDEX update -> BLOCKED (with repair steps)" -ForegroundColor Yellow
Write-Host ""
Write-Host "On macOS/Linux/WSL also run once: bash scripts/install-hooks.sh (or: chmod +x scripts/git-hooks/pre-commit scripts/*.sh)" -ForegroundColor DarkGray
Write-Host "Bash variants of all hook scripts ship alongside the .ps1 ones for cross-platform parity (SKILL §3.13)." -ForegroundColor DarkGray
