# post-edit-reminder.ps1 — invoked by Claude Code PostToolUse hook (.claude/settings.json).
# Emits a one-line reminder when the edited file is under src/.
# Reads tool-call payload from stdin (JSON). Silent on parse failures so it never breaks Claude.
# Force UTF-8 in/out so § and Chinese characters survive the pipe to/from Claude Code.
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try {
  $payload = [Console]::In.ReadToEnd()
  if (-not $payload) { exit 0 }
  $obj = $payload | ConvertFrom-Json -ErrorAction Stop
  $file = $null
  if ($obj.tool_input.file_path)     { $file = $obj.tool_input.file_path }
  elseif ($obj.tool_input.path)      { $file = $obj.tool_input.path }
  elseif ($obj.tool_input.notebook_path) { $file = $obj.tool_input.notebook_path }
  if (-not $file) { exit 0 }
  $norm = ($file -replace "\\","/")
  if ($norm -match "/src/" -or $norm -match "^src/") {
    Write-Output ("REMINDER (SKILL §3.13): you just modified `"" + $file + "`". Before committing: (1) update docs/CODE_INDEX.md bilingual row, (2) append to docs/DEV_LOG.md, (3) run scripts/check-consistency.ps1. The git pre-commit hook will block the commit otherwise.")
  }
} catch {
  # silent
}
exit 0
