# pre-commit.ps1 — PowerShell variant of the pre-commit hook (same logic as the bash version).
# Use this when your environment has PowerShell but not bash. Git for Windows ships bash,
# so on Windows the bash hook above works directly.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
# Cover A/C/M/R/D (additions, copies, modifications, renames, deletions) and disable rename
# detection so a rename out of src/ still appears as a src/ deletion that requires CODE_INDEX sync.
$staged = @(git diff --cached --name-only --diff-filter=ACMRD --no-renames) | Where-Object { $_ }
$srcChanged    = $staged | Where-Object { $_ -match "^src/" }
$indexChanged  = $staged | Where-Object { $_ -eq "docs/CODE_INDEX.md" }
$devlogChanged = $staged | Where-Object { $_ -eq "docs/DEV_LOG.md" }

if ($srcChanged -and -not $indexChanged) {
  Write-Host ""
  Write-Host "X Commit blocked: src/ changed but docs/CODE_INDEX.md was not updated." -ForegroundColor Red
  Write-Host ""
  Write-Host "  Files under src/ staged:" -ForegroundColor Yellow
  foreach ($f in $srcChanged) { Write-Host ("    " + $f) -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "  Fix (SKILL §3.12 / §3.13):" -ForegroundColor Yellow
  Write-Host "    1. Open docs/CODE_INDEX.md" -ForegroundColor Yellow
  Write-Host "    2. Update the bilingual rows (Responsibility EN + 職責 繁中)" -ForegroundColor Yellow
  Write-Host "    3. git add docs/CODE_INDEX.md" -ForegroundColor Yellow
  Write-Host "    4. git commit again" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  Emergency bypass (you MUST log it in docs/ENTROPY_LOG.md per SKILL §37.5 in the same commit):" -ForegroundColor DarkGray
  Write-Host "    git commit --no-verify" -ForegroundColor DarkGray
  Write-Host ""
  exit 1
}

if ($srcChanged -and -not $devlogChanged) {
  Write-Host ""
  Write-Host "? Warning: src/ changed but docs/DEV_LOG.md was not touched (SKILL §17 — convention, not hook-enforced). Continuing." -ForegroundColor DarkYellow
  Write-Host ""
}

# Soft warnings for §27/§34 completion gates the hook can detect cheaply
if ($srcChanged) {
  if (Test-Path "docs/REQUEST_LOG.md") {
    $req = Get-Content -Raw "docs/REQUEST_LOG.md"
    if ($req -notmatch "APPROVED-") {
      Write-Host "? Warning: src/ changed but no APPROVED-NNN row in docs/REQUEST_LOG.md (SKILL §3.14 / §27)." -ForegroundColor DarkYellow
    }
  }
  if (Test-Path "docs/CONVERSATION_LOG.md") {
    $cv = Get-Content -Raw "docs/CONVERSATION_LOG.md"
    if ($cv -notmatch "## Active Summary") {
      Write-Host "? Warning: docs/CONVERSATION_LOG.md missing Active Summary block (SKILL §3.15)." -ForegroundColor DarkYellow
    }
  }
}

exit 0
