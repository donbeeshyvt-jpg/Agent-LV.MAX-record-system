<#
建立開發環境.ps1  —  Scaffold a complete dev environment (docs handoff + harness + spec-kit)

用途 (繁體中文註解):
  依照 UNIVERSAL_MULTI_AGENT_DEV_SKILL.md 的規格,
  一鍵產生「文件即交接 + 機械化檢查 + Spec-Driven」的完整前置環境。
  產生後,新的 agent 只靠 docs/ 就能接手,不必掃描整個程式碼庫。

用法:
  .\建立開發環境.ps1                       # 產生到 .\示範開發環境\
  .\建立開發環境.ps1 -Path .\my-app -ProjectName "My App"
  之後執行  .\示範開發環境\scripts\check-consistency.ps1  驗證機械檢查
#>
[CmdletBinding()]
param(
  [string]$Path = '示範開發環境',
  [string]$ProjectName = 'Notes API (example)',
  [string]$Today = '2026-06-05'
)
$ErrorActionPreference = 'Stop'
if (-not [System.IO.Path]::IsPathRooted($Path)) {
  $base = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
  $Path = Join-Path $base $Path
}

function Write-File {
  param([string]$Rel, [string]$Content)
  $full = Join-Path $Path $Rel
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  # strip the leading newline that here-strings introduce
  Set-Content -LiteralPath $full -Value ($Content.TrimStart("`r","`n")) -Encoding utf8
  Write-Host ("  + " + $Rel)
}

# UTF-8 without BOM — needed for bash scripts so #! sits at byte 0
function Write-FileNoBom {
  param([string]$Rel, [string]$Content)
  $full = Join-Path $Path $Rel
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $clean = $Content.TrimStart("`r","`n")
  [System.IO.File]::WriteAllText($full, $clean, (New-Object System.Text.UTF8Encoding $false))
  Write-Host ("  + " + $Rel)
}

Write-Host ("Scaffolding dev environment -> " + $Path) -ForegroundColor Cyan

# ----------------------------------------------------------------------------
# Root: map, rules, env
# ----------------------------------------------------------------------------
Write-File 'AGENTS.md' @'
# AGENTS.md — Single Entry for ALL Agent Tools

> 所有 agent 工具(Claude Code / Cursor / Codex / Gemini CLI / Aider / Copilot / 本地 LLM / 純人類)的唯一入口。
> Every agent reads THIS file + docs/ first to understand the project. There are NO per-vendor instruction files.
> Map, not manual (~100 lines): point to deeper docs; don't inline everything.

## You MUST keep docs in sync as you work (隨時記錄 / 更新 / 修改)
Whenever you change code, or the user gives new direction, update the docs IN THE SAME turn:
- `docs/CODE_INDEX.md` — after any src/ change (the pre-commit hook BLOCKS the commit otherwise)
- `docs/DEV_LOG.md` — what you did + why
- `docs/CONVERSATION_LOG.md` Active Summary — the latest user direction (Claude Code auto-hook; otherwise run `scripts/log-prompt-manual.*`)
- `docs/HANDOFF.md` — so the next agent (any tool) continues cold
- `docs/REQUEST_LOG.md` — approvals (APPROVED-NNN) + timestamped corrections

## What this project is
A small REST API for personal notes. Spec is the source of truth (docs/features/).

## Start here (read in this order, then stop)
- Vision & intent: docs/PROJECT_VISION.md
- How to run / test / build: docs/00_AI_CONTEXT_INDEX.md
- Current work & handoff: docs/HANDOFF.md, docs/TASKS.md
- Code map (token-saving): docs/CODE_INDEX.md
- Conversation state (user direction): docs/CONVERSATION_LOG.md (Active Summary + last entries)
- User constraints & approvals: docs/REQUEST_LOG.md (Active Constraints, Approvals, Corrections)
- Rules you MUST follow: docs/GOLDEN_RULES.md
- Spec Kit artifact map: docs/02_SPEC_KIT_MAPPING.md

## Onboarding rule (token economy)
Read the docs above first. Do NOT scan the whole codebase. If a doc can't answer
your question, the doc is incomplete — fix it, don't scan around it.

## First action each turn (constraint reconciliation — SKILL §3.15)
Compare the latest entries in `docs/CONVERSATION_LOG.md` against the **Active User Constraints**
table in `docs/REQUEST_LOG.md`. On any disagreement:
1. Add a row to `## Corrections / Mid-flight Changes` (timestamped).
2. Toggle the conflicting constraint to `superseded`.
3. Refresh the Active Summary block of `CONVERSATION_LOG.md`.
Never silently let a new prompt override a recorded constraint.

## Non-negotiable rules (enforced mechanically)
- All required docs must exist            -> check: scripts/check-consistency.ps1
- No unresolved [NEEDS CLARIFICATION]      -> check: scripts/check-consistency.ps1
- CODE_INDEX must track code changes       -> check: scripts/check-consistency.ps1
- CODE_INDEX bilingual (EN + 繁中職責)     -> check: scripts/check-consistency.ps1
- Code comments in 繁體中文; identifiers EN -> check: scripts/check-consistency.ps1 (when src/ exists)
- Zero Simplified Chinese in docs / code   -> check: scripts/check-consistency.ps1
- src/ change WITHOUT CODE_INDEX update    -> BLOCKED by scripts/git-hooks/pre-commit (SKILL §3.13, CODE_INDEX-only)
- CONVERSATION_LOG.md auto-appended         -> Claude Code UserPromptSubmit hook (SKILL §3.15)
- Plan must be APPROVED-NNN-stamped in REQUEST_LOG.md before code (SKILL §3.14 / §13.2)

## Escape-hatch protocol
- If you MUST bypass pre-commit (`git commit --no-verify`), log the reason in `docs/ENTROPY_LOG.md` IN THE SAME COMMIT (SKILL §37.5). A bypass without an entropy log entry is a defect.
- `docs/DEV_LOG.md` updates are convention (SKILL §17), not hook-enforced — but the §27/§34 completion gate still requires them.

## Code & doc conventions (SKILL §3.12)
- Identifiers in English; **comments in 繁體中文**. Example: `// 處理登入授權`.
- `docs/CODE_INDEX.md` carries both `Responsibility (EN)` and `職責（繁中）`.
- Zero Simplified Chinese — anywhere. If pasting, convert first.

## Mechanical checks (tool-agnostic — SKILL §3.16)
Run either, depending on what your environment has:
- POSIX (macOS / Linux / WSL / Git Bash): `bash scripts/check-consistency.sh`
- Windows / pwsh anywhere: `powershell -File scripts/check-consistency.ps1`
- CI: `.github/workflows/check-consistency.yml` runs the .sh on every push / PR
A failure prints its own repair step. Fix the cause; never disable the check.

## Directory ownership
| Dir | Purpose | May edit? |
|---|---|---|
| docs/ | external memory / handoff | yes, keep current |
| docs/features/ | spec-driven feature artifacts | yes, per feature |
| scripts/ | mechanical checks | yes, with care |
| src/ | implementation (add when building) | yes |

## Do not touch without approval
- .env (never commit), production config, anything under do-not-touch in docs/00_AI_CONTEXT_INDEX.md

## Tool-agnostic operation (SKILL §3.16)
- AGENTS.md is the SINGLE entry — every tool reads this file + docs/ first. No per-vendor instruction files.
- Universal enforcement: `scripts/check-consistency.{ps1,sh}` + `scripts/git-hooks/pre-commit` + CI — works for any agent that commits, on any OS.
- Functional config only (NOT a second source of truth): `.claude/settings.json` (hooks), `.cursor/rules/` (globs), `.aider.conf.yml` (read list).
- Outside Claude Code (Codex / Gemini CLI / Aider / local LLM): run `scripts/log-prompt-manual.{ps1,sh} "<user prompt>"` once per turn to keep CONVERSATION_LOG fresh.
'@

# No CLAUDE.md / GEMINI.md / copilot-instructions.md pointer files: AGENTS.md is the single entry
# (SKILL §3.16). Aider gets a FUNCTIONAL load-config below (a read: list, not a rules copy) so it
# preloads AGENTS.md + key docs and onboards docs-first.
Write-FileNoBom '.aider.conf.yml' @'
# Aider config (SKILL §3.16) — FUNCTIONAL load-config, NOT a rules copy.
# Preloads the single source of truth (AGENTS.md) + key docs so Aider onboards docs-first.
# Universal enforcement (pre-commit hook + check-consistency) still applies regardless.
read:
  - AGENTS.md
  - docs/CODE_INDEX.md
  - docs/HANDOFF.md
  - docs/CONVERSATION_LOG.md
auto-commits: false
'@

Write-FileNoBom '.cursor/rules/project-rules.mdc' @'
---
description: Pointer to the single source of truth, AGENTS.md (SKILL §3.16)
alwaysApply: true
---

# This project follows AGENTS.md

**Read `AGENTS.md` first — it is the single source of truth.** The full rules and the
docs map live there; this file deliberately does NOT copy them (so they can never drift).

Critical reminders Cursor should always keep in view:
- After ANY change under `src/`, also update `docs/CODE_INDEX.md` — the git pre-commit hook BLOCKS the commit otherwise.
- For non-trivial work, get user approval (APPROVED-NNN in `docs/REQUEST_LOG.md`) BEFORE writing code.
- Keep `docs/CONVERSATION_LOG.md` Active Summary current each turn.
- Everything else: see `AGENTS.md`.
'@

Write-FileNoBom '.gitignore' @'
.env
node_modules/
dist/
*.log
'@

Write-FileNoBom '.env.example' @'
# Copy to .env (never commit .env)
NOTES_DB_URL=sqlite://./notes.db
API_KEY=changeme
'@

Write-File 'README.md' @'
# Dev Environment (generated)

This folder was generated by `建立開發環境.ps1` to match
**UNIVERSAL_MULTI_AGENT_DEV_SKILL.md**.

It demonstrates the three layers in service of one goal:
- **Goal** — docs-first handoff & token economy (new agent reads docs/, never scans code)
- **Spec Kit** — spec-driven backbone (docs/features/001-example-feature/)
- **Superpowers** — professional perspectives per phase
- **Harness** — mechanical enforcement (scripts/check-consistency.ps1)

Code & doc convention (SKILL §3.12): identifiers in English, **comments in 繁體中文**, and `docs/CODE_INDEX.md` is bilingual (`Responsibility (EN)` + `職責（繁中）`). Zero Simplified Chinese — enforced by the check script.

## One-time setup (install hooks — SKILL §3.13)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install-hooks.ps1
# On macOS/Linux/WSL also: chmod +x scripts/git-hooks/pre-commit
```

Or manually:
```powershell
git init
git config core.hooksPath scripts/git-hooks
```

After this, the **commit-time gate** is active: editing anything under `src/` and
trying to commit without also staging `docs/CODE_INDEX.md` will be **blocked**
with a repair message. The `.claude/settings.json` PostToolUse hook and the
Cursor rule under `.cursor/rules/` are already in place — new agents get the
edit-time reminder automatically.

## Try it

```powershell
# Assume git identity is configured. If not, set one for the demo:
# git config user.email "demo@example.local" ; git config user.name "Demo"

# 1) run the mechanical check (should PASS on the fresh scaffold)
powershell -ExecutionPolicy Bypass -File scripts/check-consistency.ps1

# 2) break it on purpose to see self-correcting failure:
Remove-Item docs/HANDOFF.md ; powershell -File scripts/check-consistency.ps1

# 3) try the pre-commit gate (covers add, modify, rename AND delete):
New-Item -ItemType Directory -Force src | Out-Null
"// 測試" | Set-Content src/test.ts
git add src/test.ts
git commit -m "test"    # <-- BLOCKED, with repair instructions
```

## First prompt for a new agent
> Read AGENTS.md and the docs it points to (PROJECT_VISION, 00_AI_CONTEXT_INDEX,
> HANDOFF, TASKS, CODE_INDEX, GOLDEN_RULES, CONVERSATION_LOG). Run scripts/check-consistency.ps1.
> Summarize state (including the CONVERSATION_LOG Active Summary so you know where the user is),
> then continue the next safe task in docs/HANDOFF.md. Do not scan the codebase.
>
> Reminders: after any change to `src/`, also update `docs/CODE_INDEX.md` — the pre-commit hook
> will block the commit otherwise (SKILL §3.13). For non-trivial work, present the plan and wait
> for APPROVED-NNN in REQUEST_LOG.md before writing code (SKILL §3.14). Refresh CONVERSATION_LOG.md
> Active Summary at the end of each substantive turn (SKILL §3.15).
'@

# ----------------------------------------------------------------------------
# scripts/ : the runnable mechanical check (harness)
# ----------------------------------------------------------------------------
Write-File 'scripts/check-consistency.ps1' @'
# check-consistency.ps1 — mechanical consistency checks (harness guardrail)
# Each failure prints a repair instruction so any agent can self-correct.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$script:fail = 0
function Fail($msg, $fix) {
  Write-Host ("X  " + $msg) -ForegroundColor Red
  Write-Host ("   Fix: " + $fix) -ForegroundColor Yellow
  $script:fail++
}
function Ok($msg) { Write-Host ("OK " + $msg) -ForegroundColor Green }

# 1) Required docs exist (docs-first handoff would break otherwise)
$required = @(
  "docs/00_AI_CONTEXT_INDEX.md","docs/02_SPEC_KIT_MAPPING.md","docs/PROJECT_VISION.md",
  "docs/REQUEST_LOG.md","docs/REQUIREMENTS.md","docs/TASKS.md","docs/CODE_INDEX.md",
  "docs/HANDOFF.md","docs/GOLDEN_RULES.md","docs/CONVERSATION_LOG.md","AGENTS.md"
)
foreach ($r in $required) {
  if (Test-Path (Join-Path $root $r)) { Ok ("exists: " + $r) }
  else { Fail ("missing required doc: " + $r) ("create " + $r + " (see SKILL.md Section 30 template)") }
}

# 2) No unresolved [NEEDS CLARIFICATION] markers in any feature spec
$featDir = Join-Path $root "docs/features"
if (Test-Path $featDir) {
  $specs = Get-ChildItem -Path $featDir -Recurse -Filter "spec.md" -ErrorAction SilentlyContinue
  foreach ($s in $specs) {
    $hit = Select-String -Path $s.FullName -Pattern "NEEDS CLARIFICATION" -SimpleMatch -ErrorAction SilentlyContinue
    if ($hit) { Fail ($s.FullName + ": unresolved NEEDS CLARIFICATION marker") "resolve via /clarify and record it in the Clarifications section before planning" }
    else { Ok ("spec clarified: " + $s.Directory.Name + "/spec.md") }
  }
}

# 3) GOLDEN_RULES has at least one rule row
$gr = Join-Path $root "docs/GOLDEN_RULES.md"
if (Test-Path $gr) {
  if (Select-String -Path $gr -Pattern "^\| GR-" -Quiet) { Ok "golden rules present" }
  else { Fail "GOLDEN_RULES.md has no GR- rows" "add a rule row, e.g. | GR-001 | rule | good | bad | check |" }
}

# 4) CODE_INDEX freshness — warn if any src file is newer than the index
$ci = Join-Path $root "docs/CODE_INDEX.md"
$srcDir = Join-Path $root "src"
if ((Test-Path $ci) -and (Test-Path $srcDir)) {
  $ciTime = (Get-Item $ci).LastWriteTime
  $stale = Get-ChildItem -Path $srcDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt $ciTime }
  if ($stale) { Fail ("CODE_INDEX.md is older than " + $stale.Count + " source file(s)") "update docs/CODE_INDEX.md to reflect recent code, then re-run this script" }
  else { Ok "CODE_INDEX fresh" }
}

# 5) CODE_INDEX is bilingual — must carry the 職責（繁中） column (SKILL §3.12 / GR-005)
if (Test-Path $ci) {
  if (Select-String -Path $ci -Pattern "職責" -SimpleMatch -Quiet) { Ok "CODE_INDEX bilingual (EN + 繁中職責)" }
  else { Fail "CODE_INDEX missing 繁中職責 column (bilingual format)" "add a | 職責（繁中） | column to the Module Map header per SKILL.md §3.12 / §18" }
}

# 5b) CONVERSATION_LOG has Active Summary block (SKILL §3.15)
$conv = Join-Path $root "docs/CONVERSATION_LOG.md"
if (Test-Path $conv) {
  if (Select-String -Path $conv -Pattern "## Active Summary" -SimpleMatch -Quiet) { Ok "CONVERSATION_LOG Active Summary block present" }
  else { Fail "CONVERSATION_LOG.md missing Active Summary block" "add `## Active Summary` block (with 最新方向/最近修正/未決問題/最近批准) per SKILL §3.15 / §30 template" }
}

# 5c) Doc-sync hooks installed (SKILL §3.13)
try {
  $hooksPath = & git -C $root config --get core.hooksPath 2>$null
  if ($hooksPath -and $hooksPath.Trim() -eq "scripts/git-hooks") {
    Ok "doc-sync hooks installed (core.hooksPath = scripts/git-hooks)"
  } elseif (-not (Test-Path (Join-Path $root ".git"))) {
    Write-Host "?  no git repo yet — run scripts/install-hooks.ps1 before code work (SKILL §3.13)" -ForegroundColor DarkYellow
  } else {
    Fail "core.hooksPath not set to scripts/git-hooks" "run scripts/install-hooks.ps1 (or: git config core.hooksPath scripts/git-hooks)"
  }
} catch { }

# 5d) .claude/settings.json wires both Claude Code hooks (SKILL §3.13 / §3.15)
$settings = Join-Path $root ".claude/settings.json"
if (Test-Path $settings) {
  try {
    $cfg = Get-Content -Raw -LiteralPath $settings -Encoding utf8 | ConvertFrom-Json
    $postOK = $false; $userOK = $false
    if ($cfg.hooks.PostToolUse) {
      foreach ($p in $cfg.hooks.PostToolUse) {
        if ($p.matcher -match "Edit|Write|MultiEdit") {
          foreach ($h in $p.hooks) { if ($h.command -match "post-edit-reminder") { $postOK = $true } }
        }
      }
    }
    if ($cfg.hooks.UserPromptSubmit) {
      foreach ($u in $cfg.hooks.UserPromptSubmit) {
        foreach ($h in $u.hooks) { if ($h.command -match "log-user-prompt") { $userOK = $true } }
      }
    }
    if ($postOK) { Ok "PostToolUse hook wired (Edit|Write|MultiEdit -> post-edit-reminder)" }
    else { Fail "PostToolUse hook missing or misconfigured in .claude/settings.json" "add a PostToolUse entry with matcher 'Edit|Write|MultiEdit' calling scripts/post-edit-reminder.* (SKILL §3.13)" }
    if ($userOK) { Ok "UserPromptSubmit hook wired (log-user-prompt)" }
    else { Fail "UserPromptSubmit hook missing or misconfigured in .claude/settings.json" "add a UserPromptSubmit entry calling scripts/log-user-prompt.* (SKILL §3.15)" }
  } catch {
    Fail ".claude/settings.json could not be parsed as JSON" ("fix syntax: " + $_.Exception.Message)
  }
} else {
  Write-Host "?  no .claude/settings.json — hooks won't auto-fire in Claude Code (SKILL §3.13 / §3.15)" -ForegroundColor DarkYellow
}

# 5d.2) AGENTS.md is the single declared entry (SKILL §3.16) — every tool reads it first
$agentsFile = Join-Path $root "AGENTS.md"
if (Test-Path $agentsFile) {
  if (Select-String -Path $agentsFile -Pattern "Single Entry for ALL|唯一入口" -Quiet) {
    Ok "AGENTS.md is the declared single entry (SKILL §3.16)"
  } else {
    Write-Host "?  AGENTS.md doesn't declare itself the universal entry — add a header line so every tool reads it first (SKILL §3.16)" -ForegroundColor DarkYellow
  }
}

# 5d.3) Manual conversation log fallback exists (for non-Claude-Code agents)
if ((Test-Path (Join-Path $root "scripts/log-prompt-manual.ps1")) -or (Test-Path (Join-Path $root "scripts/log-prompt-manual.sh"))) {
  Ok "manual CONVERSATION_LOG appender present (scripts/log-prompt-manual.*) for tool-agnostic use (SKILL §3.16)"
} else {
  Fail "missing scripts/log-prompt-manual.ps1 / .sh" "regenerate from skill or add a manual conversation-log appender so non-Claude-Code agents can keep the log fresh (SKILL §3.16)"
}

# 5e) Each in-progress feature folder needs an APPROVED-NNN row (SKILL §3.14)
$reqLog = Join-Path $root "docs/REQUEST_LOG.md"
$featDir2 = Join-Path $root "docs/features"
if ((Test-Path $featDir2) -and (Test-Path $reqLog)) {
  $reqContent = Get-Content -Raw -LiteralPath $reqLog -Encoding utf8
  $featureFolders = Get-ChildItem -Path $featDir2 -Directory -ErrorAction SilentlyContinue
  foreach ($ff in $featureFolders) {
    if ($ff.Name -match "^(\d{3})") {
      $featNum = $matches[1]
      $tasksFile = Join-Path $ff.FullName "tasks.md"
      $hasPending = $false
      if (Test-Path $tasksFile) {
        if (Select-String -Path $tasksFile -Pattern "Status:\s*(pending|in[-_ ]?progress)" -Quiet) { $hasPending = $true }
      }
      if ($hasPending) {
        # Require the literal APPROVED-NNN AND the feature folder reference on the same markdown table row.
        $rowPattern = "(?m)^\|[^\r\n]*APPROVED-" + $featNum + "\b[^\r\n]*features/" + [regex]::Escape($ff.Name)
        if ($reqContent -match $rowPattern) {
          Ok ("APPROVED-" + $featNum + " row found for " + $ff.Name)
        } else {
          Fail ("no APPROVED-" + $featNum + " row referencing docs/features/" + $ff.Name + " in REQUEST_LOG.md (SKILL §3.14)") ("add an Approvals table row with BOTH APPROVED-" + $featNum + " AND docs/features/" + $ff.Name + " before any TASK in that folder is implemented")
        }
      }
    }
  }
}

# 5f) Conversation-log recency (SKILL §3.15 — mechanical reminder for non-Claude tools)
# If newest CONV-NNN timestamp is >24h old while src/ has recent changes, warn (soft).
if ((Test-Path $conv) -and (Test-Path $srcDir)) {
  $stamps = Select-String -Path $conv -Pattern "^### (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) — CONV-\d{3}" -AllMatches
  if ($stamps) {
    $latest = ($stamps | ForEach-Object { [datetime]::ParseExact($_.Matches[0].Groups[1].Value, "yyyy-MM-dd HH:mm:ss", $null) } | Sort-Object -Descending | Select-Object -First 1)
    $latestSrc = Get-ChildItem -Path $srcDir -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestSrc) {
      $ageHours = ($latestSrc.LastWriteTime - $latest).TotalHours
      if ($ageHours -gt 24) {
        Write-Host ("?  CONVERSATION_LOG looks stale: newest CONV entry is " + [int]$ageHours + "h older than the latest src/ change. Run scripts/log-prompt-manual.* (or rely on Claude Code auto-hook). SKILL §3.15 / §3.16.") -ForegroundColor DarkYellow
      } else { Ok ("CONVERSATION_LOG recency OK (newest CONV within 24h of latest src/ change)") }
    }
  }
}

# 6) Zero Simplified Chinese in tracked docs (GR-006)
#    Heuristic sampler — high-frequency Simplified-only characters.
#    Expand the list as you encounter misses; or wire in opencc for full coverage.
$simplifiedSamples = @(
  "仓","库","执","档","贷","专","业","实","现","进","环","时","让","这","个",
  "们","来","过","应","该","发","问","题","简","体","转","换","质","类","别",
  "样","线","点","边","单","语","经","编","开","级","产","学","国","务","议",
  "给","处","标","头","报","设","计","选","择","历","继","续","结","论","号"
) | Sort-Object -Unique

$bad = @()
$docsDir = Join-Path $root "docs"
$scan = @()
if (Test-Path $docsDir) { $scan += @(Get-ChildItem -Path $docsDir -Recurse -Include *.md -File -ErrorAction SilentlyContinue) }
$agentsMd = Join-Path $root "AGENTS.md"
if (Test-Path $agentsMd) { $scan += (Get-Item $agentsMd) }
foreach ($f in $scan) {
  foreach ($s in $simplifiedSamples) {
    if (Select-String -Path $f.FullName -Pattern $s -SimpleMatch -Quiet) {
      $bad += ($f.FullName.Substring($root.Length+1) + " contains Simplified '" + $s + "'")
      break  # one finding per file is enough
    }
  }
}
if ($bad.Count -eq 0) { Ok ("no Simplified Chinese in " + $scan.Count + " doc files (sampler: " + $simplifiedSamples.Count + " chars)") }
else { foreach ($b in $bad) { Fail $b "convert to Traditional Chinese; never paste Simplified text (SKILL §3.12 / GR-006)" } }

# 7) Code-comment convention scan — backs GR-004 enforcement (only when src/ exists)
if (Test-Path $srcDir) {
  $codeExt = @(".js",".ts",".jsx",".tsx",".mjs",".cjs",".py",".go",".rs",".cs",".java",".rb",".php",".cpp",".cc",".c",".h",".hpp",".swift",".kt",".scala",".sh",".ps1",".psm1")
  $codeFiles = @(Get-ChildItem -Path $srcDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $codeExt -contains $_.Extension.ToLower() })
  $codeBad = @()
  $warnNoChinese = @()
  foreach ($f in $codeFiles) {
    $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    # Hard fail: Simplified inside code file (GR-006)
    foreach ($s in $simplifiedSamples) {
      if ($content.Contains($s)) {
        $codeBad += ($f.FullName.Substring($root.Length+1) + " (src) contains Simplified '" + $s + "'")
        break
      }
    }
    # Soft warn: file has comments but zero CJK characters → likely missing 繁中 (GR-004)
    $hasComment = [regex]::IsMatch($content, "(^|\r|\n)\s*(//|#|/\*|\*|<!--)")
    $hasCjk = [regex]::IsMatch($content, "\p{IsCJKUnifiedIdeographs}")
    if ($hasComment -and -not $hasCjk) { $warnNoChinese += $f.FullName.Substring($root.Length+1) }
  }
  foreach ($b in $codeBad) { Fail $b "convert to Traditional Chinese (SKILL §3.12 / GR-006)" }
  if ($codeBad.Count -eq 0 -and $codeFiles.Count -gt 0) { Ok ("code files clean of Simplified (" + $codeFiles.Count + " files scanned)") }
  if ($warnNoChinese.Count -gt 0) {
    Write-Host ("?  " + $warnNoChinese.Count + " code file(s) have comments but no 繁體中文 (GR-004 hint — soft warn, not a hard fail):") -ForegroundColor DarkYellow
    foreach ($w in ($warnNoChinese | Select-Object -First 5)) { Write-Host ("   - " + $w) -ForegroundColor DarkYellow }
    Write-Host ("   Hint: comments should default to 繁體中文 per SKILL §3.12 / GR-004. Override OK if file is auto-generated or uses doc-comments by deliberate exception (log in DECISION_LOG.md).") -ForegroundColor DarkYellow
  }
}

Write-Host ""
if ($script:fail -gt 0) {
  Write-Host ("FAILED: " + $script:fail + " check(s). Fix the items above (each prints its repair step).") -ForegroundColor Red
  exit 1
} else {
  Write-Host "ALL CHECKS PASSED. A cold agent can onboard from docs/ alone." -ForegroundColor Green
  exit 0
}
'@

Write-FileNoBom 'scripts/check-consistency.sh' @'
#!/usr/bin/env bash
# check-consistency.sh — POSIX bash companion to check-consistency.ps1 (SKILL §3.16).
# Same checks; works on macOS/Linux/WSL without requiring pwsh to be installed.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
fail=0
ok()  { printf "OK %s\n" "$1"; }
warn(){ printf "?  %s\n" "$1"; }
err() { printf "X  %s\n   Fix: %s\n" "$1" "$2"; fail=$((fail + 1)); }

# 1) Required docs exist
required=("docs/00_AI_CONTEXT_INDEX.md" "docs/02_SPEC_KIT_MAPPING.md" "docs/PROJECT_VISION.md" \
          "docs/REQUEST_LOG.md" "docs/REQUIREMENTS.md" "docs/TASKS.md" "docs/CODE_INDEX.md" \
          "docs/HANDOFF.md" "docs/GOLDEN_RULES.md" "docs/CONVERSATION_LOG.md" "AGENTS.md")
for r in "${required[@]}"; do
  if [ -e "$root/$r" ]; then ok "exists: $r"
  else err "missing required doc: $r" "create $r (see SKILL.md Section 30 template)"; fi
done

# 2) No unresolved [NEEDS CLARIFICATION]
if [ -d "$root/docs/features" ]; then
  while IFS= read -r s; do
    if grep -q "NEEDS CLARIFICATION" "$s" 2>/dev/null; then
      err "$s: unresolved NEEDS CLARIFICATION marker" "resolve via /clarify before planning"
    else
      ok "spec clarified: $(basename "$(dirname "$s")")/spec.md"
    fi
  done < <(find "$root/docs/features" -name spec.md 2>/dev/null)
fi

# 3) GOLDEN_RULES has at least one GR- row
gr="$root/docs/GOLDEN_RULES.md"
if [ -f "$gr" ]; then
  if grep -qE "^\| GR-" "$gr"; then ok "golden rules present"
  else err "GOLDEN_RULES.md has no GR- rows" "add a rule row like | GR-001 | rule | good | bad | check |"
  fi
fi

# 4) CODE_INDEX freshness vs src/
ci="$root/docs/CODE_INDEX.md"; srcDir="$root/src"
if [ -f "$ci" ] && [ -d "$srcDir" ]; then
  newer=$(find "$srcDir" -type f -newer "$ci" 2>/dev/null | wc -l | tr -d " ")
  if [ "$newer" -gt 0 ]; then err "CODE_INDEX.md is older than $newer source file(s)" "update docs/CODE_INDEX.md to reflect recent code"
  else ok "CODE_INDEX fresh"
  fi
fi

# 5) CODE_INDEX bilingual + Active Summary + hooksPath + settings.json wiring
[ -f "$ci" ] && (grep -q "職責" "$ci" && ok "CODE_INDEX bilingual (EN + 繁中職責)" \
  || err "CODE_INDEX missing 繁中職責 column" "add | 職責（繁中） | column per SKILL §3.12 / §18")
conv="$root/docs/CONVERSATION_LOG.md"
[ -f "$conv" ] && (grep -q "## Active Summary" "$conv" && ok "CONVERSATION_LOG Active Summary block present" \
  || err "CONVERSATION_LOG.md missing Active Summary block" "add ## Active Summary per SKILL §3.15 / §30")
hp=$(git -C "$root" config --get core.hooksPath 2>/dev/null || true)
if [ "$hp" = "scripts/git-hooks" ]; then ok "doc-sync hooks installed (core.hooksPath = scripts/git-hooks)"
elif [ ! -d "$root/.git" ]; then warn "no git repo yet — run scripts/install-hooks.sh"
else err "core.hooksPath not set" "run scripts/install-hooks.sh"
fi

# settings.json hook wiring (grep-only; no jq required)
st="$root/.claude/settings.json"
if [ -f "$st" ]; then
  grep -q "post-edit-reminder" "$st" && ok "PostToolUse hook wired (post-edit-reminder)" \
    || err "PostToolUse hook missing in .claude/settings.json" "add PostToolUse entry calling scripts/post-edit-reminder.* (SKILL §3.13)"
  grep -q "log-user-prompt"  "$st" && ok "UserPromptSubmit hook wired (log-user-prompt)" \
    || err "UserPromptSubmit hook missing in .claude/settings.json" "add UserPromptSubmit entry calling scripts/log-user-prompt.* (SKILL §3.15)"
fi

# AGENTS.md single-entry declaration + manual log appender (SKILL §3.16)
if grep -Eq "Single Entry for ALL|唯一入口" "$root/AGENTS.md" 2>/dev/null; then
  ok "AGENTS.md is the declared single entry (SKILL §3.16)"
else
  warn "AGENTS.md doesn't declare itself the universal entry (SKILL §3.16)"
fi
if [ -e "$root/scripts/log-prompt-manual.ps1" ] || [ -e "$root/scripts/log-prompt-manual.sh" ]; then
  ok "manual CONVERSATION_LOG appender present (SKILL §3.16)"
else
  err "missing scripts/log-prompt-manual.{ps1,sh}" "regenerate so non-Claude-Code agents can keep the log fresh (SKILL §3.16)"
fi

# APPROVED-NNN ↔ feature folder (SKILL §3.14)
if [ -d "$root/docs/features" ] && [ -f "$root/docs/REQUEST_LOG.md" ]; then
  for ff in "$root"/docs/features/*/; do
    [ -d "$ff" ] || continue
    base=$(basename "$ff"); num="${base%%-*}"
    case "$num" in [0-9][0-9][0-9])
      tasks="$ff/tasks.md"
      [ -f "$tasks" ] || continue
      if grep -Eq "Status:\s*(pending|in[-_ ]?progress)" "$tasks"; then
        if grep -E "^\|.*APPROVED-${num}.*features/${base}" "$root/docs/REQUEST_LOG.md" >/dev/null 2>&1; then
          ok "APPROVED-${num} row found for ${base}"
        else
          err "no APPROVED-${num} row referencing docs/features/${base} in REQUEST_LOG.md (SKILL §3.14)" \
              "add an Approvals row with BOTH APPROVED-${num} AND docs/features/${base}"
        fi
      fi
    ;; esac
  done
fi

# Conversation-log recency (SKILL §3.15)
if [ -f "$conv" ] && [ -d "$srcDir" ]; then
  latest_conv=$(grep -oE "^### [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" "$conv" | sort -r | head -1 | sed "s/^### //")
  if [ -n "$latest_conv" ]; then
    latest_src=$(find "$srcDir" -type f -printf "%TY-%Tm-%Td %TH:%TM:%TS\n" 2>/dev/null | sort -r | head -1 | cut -c1-19)
    if [ -n "$latest_src" ]; then
      cs=$(date -d "$latest_conv" +%s 2>/dev/null || echo 0)
      ss=$(date -d "$latest_src" +%s 2>/dev/null || echo 0)
      if [ "$cs" -gt 0 ] && [ "$ss" -gt 0 ]; then
        gap=$(( (ss - cs) / 3600 ))
        if [ "$gap" -gt 24 ]; then warn "CONVERSATION_LOG stale: newest CONV is ${gap}h older than latest src/ change. Run scripts/log-prompt-manual.* (SKILL §3.15 / §3.16)."
        else ok "CONVERSATION_LOG recency OK"
        fi
      fi
    fi
  fi
fi

# Zero Simplified Chinese (sampler)
samples="仓 库 执 档 贷 专 业 实 现 进 环 时 让 这 个 们 来 过 应 该 发 问 题 简 体 单 语 经 编 开 级 产 学 国 务 给 处 标 头 报"
bad=0
while IFS= read -r f; do
  for s in $samples; do
    if grep -q "$s" "$f" 2>/dev/null; then
      err "${f#$root/} contains Simplified '$s'" "convert to Traditional Chinese (SKILL §3.12 / GR-006)"
      bad=$((bad + 1)); break
    fi
  done
done < <(find "$root/docs" "$root/AGENTS.md" -name "*.md" -type f 2>/dev/null)
[ "$bad" -eq 0 ] && ok "no Simplified Chinese in scanned docs"

printf "\n"
if [ "$fail" -gt 0 ]; then printf "FAILED: %d check(s).\n" "$fail" >&2; exit 1; fi
printf "ALL CHECKS PASSED. A cold agent can onboard from docs/ alone.\n"
'@

Write-FileNoBom '.github/workflows/check-consistency.yml' @'
# CI guard — runs check-consistency on every push/PR so remote committers
# (GitHub Copilot Coding Agent, web edits, etc.) hit the same gate as local
# pre-commit. SKILL §3.16 universal-enforcement.
name: check-consistency

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  consistency:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run check-consistency
        run: bash scripts/check-consistency.sh
      - name: Pre-commit-equivalent — block src/ changes without CODE_INDEX update
        if: github.event_name == ''pull_request''
        run: |
          base="${{ github.event.pull_request.base.sha }}"
          changed=$(git diff --name-only --diff-filter=ACMRD --no-renames "$base"...HEAD)
          src=$(printf "%s\n" "$changed" | grep -E "^src/" || true)
          idx=$(printf "%s\n" "$changed" | grep -E "^docs/CODE_INDEX\.md$" || true)
          if [ -n "$src" ] && [ -z "$idx" ]; then
            echo "X PR blocked: src/ changed but docs/CODE_INDEX.md was not updated."
            echo "  Files: $src"
            echo "  Fix: update docs/CODE_INDEX.md bilingual row (SKILL §3.12 / §3.13)."
            exit 1
          fi
'@

Write-File 'tests/structural/README.md' @'
# Structural / invariant tests (harness guardrails)

Put repo-shape and dependency-direction tests here, e.g.:
- "no file under src/api imports from src/db directly"
- "every public function has a matching test file"

Each test must fail loudly with a repair instruction (see SKILL.md Section 35).
'@

# ----------------------------------------------------------------------------
# Hook layer (SKILL §3.13) — edit-time reminder + commit-time gate.
# Goal: docs sync is not optional; agents are mechanically forced to update
# docs/CODE_INDEX.md alongside src/ changes, so no user reminder is needed.
# ----------------------------------------------------------------------------

Write-FileNoBom 'scripts/git-hooks/pre-commit' @'
#!/usr/bin/env bash
# pre-commit — block commits where src/ changed but docs/CODE_INDEX.md was not also staged.
# SKILL §3.13 / §40 — docs move with code; no per-agent reminders needed.
# Covers additions, modifications, copies, renames AND deletions (-D), plus rename-out-of-src
# via --name-status with --no-renames so the source-side path is preserved.

staged=$(git diff --cached --name-only --diff-filter=ACMRD --no-renames)
src_changed=$(printf "%s\n" "$staged" | grep -E "^src/" || true)
index_changed=$(printf "%s\n" "$staged" | grep -E "^docs/CODE_INDEX\.md$" || true)
devlog_changed=$(printf "%s\n" "$staged" | grep -E "^docs/DEV_LOG\.md$" || true)

if [ -n "$src_changed" ] && [ -z "$index_changed" ]; then
  echo "" >&2
  echo "X Commit blocked: src/ changed but docs/CODE_INDEX.md was not updated." >&2
  echo "" >&2
  echo "  Files under src/ staged:" >&2
  printf "%s\n" "$src_changed" | sed "s/^/    /" >&2
  echo "" >&2
  echo "  Fix (SKILL §3.12 / §3.13):" >&2
  echo "    1. Open docs/CODE_INDEX.md" >&2
  echo "    2. Update the bilingual rows (Responsibility EN + 職責 繁中) for the files above" >&2
  echo "    3. git add docs/CODE_INDEX.md" >&2
  echo "    4. git commit again" >&2
  echo "" >&2
  echo "  Emergency bypass (you MUST log it in docs/ENTROPY_LOG.md per SKILL §37.5 in the same commit):" >&2
  echo "    git commit --no-verify" >&2
  echo "" >&2
  exit 1
fi

if [ -n "$src_changed" ] && [ -z "$devlog_changed" ]; then
  echo "" >&2
  echo "? Warning: src/ changed but docs/DEV_LOG.md was not touched (SKILL §17 — convention, not hook-enforced). Continuing." >&2
  echo "" >&2
fi

# Soft warnings (not blocking) for §27/§34 completion gates the hook can detect cheaply:
# (1) Plan-approval present? (2) Active Summary recent?
if [ -n "$src_changed" ]; then
  if [ -f docs/REQUEST_LOG.md ] && ! grep -q "APPROVED-" docs/REQUEST_LOG.md; then
    echo "? Warning: src/ changed but no APPROVED-NNN row in docs/REQUEST_LOG.md (SKILL §3.14 / §27)." >&2
  fi
  if [ -f docs/CONVERSATION_LOG.md ]; then
    if ! grep -q "## Active Summary" docs/CONVERSATION_LOG.md; then
      echo "? Warning: docs/CONVERSATION_LOG.md missing Active Summary block (SKILL §3.15)." >&2
    fi
  fi
fi

exit 0
'@

Write-File 'scripts/git-hooks/pre-commit.ps1' @'
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
'@

Write-File 'scripts/post-edit-reminder.ps1' @'
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
'@

Write-FileNoBom '.claude/settings.json' @'
{
  "_comment": "Claude Code project settings — hooks per SKILL §3.13 (doc sync) and §3.15 (conversation log). Commit this file so every agent gets the edit-time reminder and the conversation log auto-appends.",
  "_cross_platform": "Defaults to PowerShell (Windows / pwsh on macOS/Linux). For pure macOS/Linux/WSL with bash, replace the commands with: bash $CLAUDE_PROJECT_DIR/scripts/post-edit-reminder.sh and bash $CLAUDE_PROJECT_DIR/scripts/log-user-prompt.sh (both .sh variants are shipped). $CLAUDE_PROJECT_DIR is substituted by Claude Code; falls back to relative path if unsupported.",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "^(Edit|Write|MultiEdit|NotebookEdit)$",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR/scripts/post-edit-reminder.ps1\""
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"$CLAUDE_PROJECT_DIR/scripts/log-user-prompt.ps1\""
          }
        ]
      }
    ]
  }
}
'@

Write-File 'scripts/log-user-prompt.ps1' @'
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
'@

Write-File 'scripts/install-hooks.ps1' @'
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
'@

Write-FileNoBom 'scripts/post-edit-reminder.sh' @'
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
'@

Write-FileNoBom 'scripts/log-user-prompt.sh' @'
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
'@

Write-FileNoBom 'scripts/install-hooks.sh' @'
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
'@

Write-File 'scripts/log-prompt-manual.ps1' @'
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
'@

Write-FileNoBom 'scripts/log-prompt-manual.sh' @'
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
'@

Write-FileNoBom '.cursor/rules/sync-docs-on-src-edit.mdc' @'
---
description: Sync docs/CODE_INDEX.md and DEV_LOG.md when editing src/
globs: ["src/**/*"]
alwaysApply: false
---

# Doc sync on src/ edits (SKILL §3.13)

Whenever you modify any file under `src/`:

1. Update the matching row in `docs/CODE_INDEX.md` — bilingual: `Responsibility (EN)` + `職責（繁中）`.
2. Append a brief entry to `docs/DEV_LOG.md` for the change.
3. Run `scripts/check-consistency.ps1`.

The git pre-commit hook BLOCKS commits where `src/` changed but `docs/CODE_INDEX.md` was not staged. Don't bypass it — fix the index instead.
'@

# ----------------------------------------------------------------------------
# docs/ : external memory
# ----------------------------------------------------------------------------
Write-File 'docs/00_AI_CONTEXT_INDEX.md' @"
# AI Context Index

Last updated: $Today

## Project Purpose
$ProjectName — a minimal REST API to create, list, and delete personal notes.

## User / Product Goal
Let a single user store short notes and retrieve them by id or list.

## Current Status
Planning complete for feature 001 (CRUD notes). Implementation not started.

## Tech Stack
TODO: choose at /plan time. Default: Node + Express + SQLite (boring, agent-readable).

## How to Run
TODO (after implementation): ``npm start``

## How to Test
TODO (after implementation): ``npm test``

## How to Build
TODO (after implementation): ``npm run build``

## Current Feature
001-example-feature — CRUD notes (see docs/features/001-example-feature/).

## Architecture Summary
See docs/ARCHITECTURE.md (single service, thin API -> service -> storage).

## Important Files
See docs/CODE_INDEX.md (the token-saving map).

## Do Not Touch Without Approval
.env, production database.

## Known Risks
None yet (greenfield).

## Next Safe Step
Implement TASK-001 (see docs/features/001-example-feature/tasks.md).
"@

Write-File 'docs/02_SPEC_KIT_MAPPING.md' @"
# Spec Kit Mapping

Last updated: $Today

Where each Spec-Driven Development artifact lives in this repo.

| Spec Kit command | Artifact | Location here |
|---|---|---|
| /constitution | governing principles | docs/REQUIREMENTS.md + docs/GOLDEN_RULES.md |
| /specify | spec.md | docs/features/NNN-*/spec.md |
| /clarify | Clarifications section | docs/features/NNN-*/spec.md |
| /plan | plan + supporting docs | docs/features/NNN-*/plan.md |
| /tasks | task list | docs/features/NNN-*/tasks.md |
| /analyze | consistency report | note in tasks.md / docs/SELF_CHECK.md |
| /implement | code + tests | src/ + tests/ |

If the real Spec Kit CLI is installed, its ``specs/{feature}/`` layout is the
equivalent of ``docs/features/NNN-*/`` here. Keep this file current.
"@

Write-File 'docs/PROJECT_VISION.md' @"
# Project Vision

Last updated: $Today
Vision version: 1

## One-Sentence Core
A dead-simple personal notes API that is easy for AI agents to extend safely.

## User's Original Intent
"I want to store and retrieve short notes via a small API."

## Product North Star
Smallest correct CRUD API; spec stays the source of truth.

## Target Users
A single developer storing personal notes.

## Primary Use Cases
Create a note, list notes, delete a note.

## Non-Goals
Multi-user auth, sharing, rich text, sync.

## Non-Negotiable Constraints
Spec-driven; docs-first handoff; mechanical checks must pass.

## Revision History
| Version | Date | Change | Reason |
|---|---|---|---|
| 1 | $Today | initial vision | scaffold |
"@

Write-File 'docs/REQUEST_LOG.md' @"
# Request Log

Last updated: $Today

## Active User Constraints
| ID | Constraint | Source | Status |
|---|---|---|---|
| C-001 | Keep it single-user, no auth | initial | active |

## Approvals (SKILL §3.14 / §13.2 — CANONICAL FORMAT)
<!-- Each implementation start requires an APPROVED-NNN entry here, timestamped.
     Optional ### APPROVED-NNN paragraph blocks can sit below for richer notes,
     but the row is the source of truth (check-consistency parses it). -->
| Timestamp | ID | Feature scope approved | Source | Open questions resolved | Constraints carried over | Status |
|---|---|---|---|---|---|---|
| $Today 09:00:00 | APPROVED-001 | docs/features/001-example-feature TASK-001..003 (CRUD notes) | user (scaffold) | Q1 auth (no), Q2 max-len (1000), Q3 storage (sqlite) | C-001 single-user | active |

### APPROVED-001 — Feature 001 plan
Source: user (initial scaffold)
Scope approved: TASK-001..TASK-003 per docs/features/001-example-feature/{spec,plan,tasks}.md
Open questions resolved: Q1 = no auth, Q2 = 1000-char limit, Q3 = SQLite storage (DEC-001)
Constraints carried over: C-001 single-user

## Corrections / Mid-flight Changes (timestamped)
<!-- Whenever the user redirects mid-task, log it here so future agents see the latest direction.
     Active Constraints reconciliation rule (SKILL §3.15): each turn, compare latest CONV entries
     against the constraints table; on disagreement add a row here and toggle the constraint
     to 'superseded'. -->
| Timestamp | What changed | Why | Affected docs / tasks | Status |
|---|---|---|---|---|

## Request Entries
### $Today — REQ-001 — Build a notes API
User intent summary: store and retrieve short notes via a small API.
Converted into: feature 001-example-feature.
Status: planned.
"@

Write-File 'docs/INTENT_TRACE.md' @"
# Intent Trace

Last updated: $Today

| Intent ID | User Need | Requirement | Feature Spec | Task ID | Status |
|---|---|---|---|---|---|
| INTENT-001 | store/retrieve notes | CRUD notes | 001-example-feature | TASK-001..003 | planned |
"@

Write-File 'docs/ARCHITECTURE.md' @"
# Architecture

Last updated: $Today

Single service. Layered: API (HTTP) -> Service (rules) -> Storage (DB).
Dependency direction is one-way (API -> Service -> Storage); enforce with a structural test.
"@

Write-File 'docs/REQUIREMENTS.md' @"
# Requirements / Constitution

Last updated: $Today

## Principles (constitution)
- Library/Service-first; thin API layer.
- Test-First (NON-NEGOTIABLE): tests before implementation.
- Simplicity Gate: fewest moving parts; justify extra layers in DECISION_LOG.
- Anti-Abstraction Gate: use the framework directly; justify wrappers.
- Integration-First Gate: contract/integration tests before implementation.
- Language convention (SKILL §3.12): 繁體中文 comments, English identifiers / commits, bilingual CODE_INDEX, zero Simplified Chinese. Override only by deliberate decision in DECISION_LOG.
- User-approval gate (SKILL §3.14 / §13.2): no code is written from an unapproved plan; approval recorded as APPROVED-NNN in REQUEST_LOG.md before implementation.
- Doc-sync hook (SKILL §3.13): pre-commit hook blocks src/ commits without CODE_INDEX update.
- Conversation-log hook (SKILL §3.15): UserPromptSubmit hook auto-appends prompts to docs/CONVERSATION_LOG.md; agent maintains rolling Active Summary.

## Forbidden
placeholder completion, fake tests, committing secrets, pushing to main without approval,
disabling checks to pass CI, touching unrelated files.
"@

Write-File 'docs/GOLDEN_RULES.md' @"
# Golden Rules

Last updated: $Today

> Canonical patterns every agent must replicate. Backed by a check where possible.

| ID | Rule | Good example | Bad example | Enforced by (check) |
|---|---|---|---|---|
| GR-001 | All required docs must exist | full docs/ set | missing HANDOFF | scripts/check-consistency.ps1 |
| GR-002 | No unresolved clarification markers in specs | clarified spec | open marker left in spec | scripts/check-consistency.ps1 |
| GR-003 | CODE_INDEX tracks code changes | index updated with code | stale index | scripts/check-consistency.ps1 |
| GR-004 | Code comments in 繁體中文; identifiers in English | ``// 處理登入授權`` | ``// handle login`` or Simplified | scripts/check-consistency.ps1 |
| GR-005 | CODE_INDEX bilingual (EN + 繁中職責) | row has both columns | EN-only or 繁中-only | scripts/check-consistency.ps1 |
| GR-006 | Zero Simplified Chinese anywhere | 繁體 ``倉庫``、``執行`` | (any Simplified equivalent — the check will name it) | scripts/check-consistency.ps1 |

## Notes
New code must follow these. Drift is logged in docs/ENTROPY_LOG.md.
A rule that matters but has no check yet is a TODO: add the check.
"@

Write-File 'docs/ENTROPY_LOG.md' @"
# Entropy Log

Last updated: $Today

> Drift from the golden rules and accumulating tech debt (高息貸款 — high-interest debt).

No drift recorded yet. Add ENTROPY-NNN entries when patterns deviate or debt is taken on. Pre-commit hook bypasses (``git commit --no-verify``) MUST be logged here per SKILL §37.5.
"@

Write-File 'docs/CONVERSATION_LOG.md' @"
# Conversation Log

> 自動由 Claude Code UserPromptSubmit hook 寫入 (SKILL §3.15)。
> 新接手的 agent 讀這份就能知道使用者對話進行到哪。
> Auto-appended by the UserPromptSubmit hook (scripts/log-user-prompt.ps1). A new agent reads this to know where the user's conversation is currently at.

Last updated: $Today (initial scaffold)

## Active Summary
<!-- Rolling. Agent updates this block at the end of every substantive turn (Section 27 / 34). Keep to ~10 lines. -->

最新方向 / Latest direction: (scaffold) 開發環境剛建立,等使用者下指示。
最近修正 / Recent corrections: (none yet)
未決問題 / Open questions: (none yet)
最近批准 / Recent approvals (APPROVED-NNN refs): (none yet)

## Log Entries
<!-- The UserPromptSubmit hook appends ### YYYY-MM-DD HH:MM:SS — CONV-NNN entries here. -->
"@

Write-File 'docs/TASKS.md' @"
# Task Index

Last updated: $Today

| Task ID | Feature | Status | Branch | Verification | Commit |
|---|---|---|---|---|---|
| TASK-001 | 001-example-feature | pending | feature/001-notes | unit + manual POST | — |
| TASK-002 | 001-example-feature | pending | feature/001-notes | unit + manual GET | — |
| TASK-003 | 001-example-feature | pending | feature/001-notes | unit + manual DELETE | — |
"@

Write-File 'docs/DEV_LOG.md' @"
# Development Log

## $Today — SCAFFOLD
Change: generated docs-first dev environment.
Tests: scripts/check-consistency.ps1 (passes).
Next: implement TASK-001.
"@

Write-File 'docs/DECISION_LOG.md' @"
# Decision Log

## $Today — DEC-001 — Use SQLite for storage
Context: single-user notes, no scale needs.
Decision: SQLite (boring, stable API, agent-readable).
Alternatives: Postgres (overkill), in-memory (not durable).
Rollback: swap storage layer behind the Service interface.
"@

Write-File 'docs/SELF_CHECK.md' @"
# Self Check

## $Today — SCAFFOLD
Spec compliance: n/a (no code yet).
Mechanical checks: PASS (scripts/check-consistency.ps1).
Docs check: all required docs present.
Verdict: ready to implement TASK-001.
"@

Write-File 'docs/TEST_REPORT.md' @"
# Test Report

## $Today — SCAFFOLD
Environment: scaffold only.
Automated tests: none yet.
Mechanical checks: scripts/check-consistency.ps1 -> ALL CHECKS PASSED.
Not run: app tests (no implementation yet).
"@

Write-File 'docs/CODE_INDEX.md' @"
# Code Index

Last updated: $Today

> 雙語索引 (English + 繁體中文)。新 agent 先讀這份,即可定位 1–3 個關鍵檔,不必掃整個專案。
> Bilingual map of the codebase. A new agent reads this first to locate the 1–3 files a task needs without opening anything else.

## Module Map (planned — fill as code lands)
| Path | Responsibility (EN) | 職責（繁中） | Public API | Used By | Tests | Risk |
|---|---|---|---|---|---|---|
| src/api/notes.* | HTTP routes for notes | 對外 HTTP 路由：建立／列出／刪除筆記 | POST/GET/DELETE /notes | server | tests/api/notes.* | low |
| src/service/notes.* | note rules (validate, ids) | 商業邏輯：驗證輸入、產生 id、組裝回應 | createNote/listNotes/deleteNote | api | tests/service/* | low |
| src/storage/notes.* | persistence (SQLite) | 持久化層：SQLite 讀寫筆記資料 | save/all/remove | service | tests/storage/* | med |

No source files exist yet; rows above are the planned shape from the spec. 尚無實作檔案;以上為依規格規劃的雛型。

<!-- Optional per-file detail block — add when a single row isn't enough.
     新增程式碼後,可在此區追加每個檔案的詳細條目。範本:
## src/api/notes.ts
Responsibility (EN): HTTP routes for /notes (POST/GET/DELETE)
職責（繁中）: 對外 HTTP 路由,呼叫 service 層處理筆記 CRUD
Public functions/classes: registerRoutes(app)
Depends on: src/service/notes
Used by: src/server.ts
Related tests: tests/api/notes.test.ts
Change risk: low
Notes / 備註: 驗證錯誤統一回 400;失敗回 500。
-->
"@

Write-File 'docs/HANDOFF.md' @"
# Handoff

Last updated: $Today

## Current State
Scaffold complete. Feature 001 (CRUD notes) is specified, planned, and broken into tasks.
Mechanical checks pass. No implementation yet.

## Last Completed Task
SCAFFOLD (dev environment generated).

## Current Branch
none yet (create feature/001-notes at Phase 6).

## Changed Files
docs/* , AGENTS.md , scripts/check-consistency.ps1

## Test Status
scripts/check-consistency.ps1 -> ALL CHECKS PASSED.

## Known Risks
None (greenfield).

## Next Safe Task
TASK-001: implement POST /notes (test-first). See docs/features/001-example-feature/tasks.md.

## Do Not Touch
.env, production database.

## Useful Commands
powershell -File scripts/check-consistency.ps1

## Notes for Next Agent
Onboard from this file + AGENTS.md + docs/00_AI_CONTEXT_INDEX.md + docs/CODE_INDEX.md +
**docs/CONVERSATION_LOG.md (Active Summary + last entries — where the user is)** +
**docs/REQUEST_LOG.md (latest Approvals + Corrections — what's been agreed/changed)**.
Do not scan the codebase. The current scope (TASK-001..003) is approved as APPROVED-001 in REQUEST_LOG.md.
For any non-trivial new work,  present a fresh planning bundle and obtain APPROVED-NNN BEFORE writing code (SKILL §3.14).
"@

# ----------------------------------------------------------------------------
# docs/features/001-example-feature : Spec-Driven artifacts
# ----------------------------------------------------------------------------
Write-File 'docs/features/001-example-feature/spec.md' @"
# Feature Spec: 001 Example Feature — CRUD Notes

## User Problem
A user needs to store short notes and get them back later.

## Goal
Provide create, list, and delete operations for notes via HTTP.

## Non-Goals
Auth, multi-user, edit/update, search.

## Primary User Flow
Create a note -> see it in the list -> delete it.

## Acceptance Criteria
- AC-1: POST /notes with {text} returns 201 and the created note with an id.
- AC-2: GET /notes returns all notes as a JSON array.
- AC-3: DELETE /notes/{id} returns 204 and removes the note.
- AC-4: POST /notes with empty text returns 400.

## Clarifications
(resolved during /clarify — no open markers remain)
- Q1: Auth required? -> A: No. Single-user, decided $Today (constraint C-001).
- Q2: Max note length? -> A: 1000 chars; longer returns 400.
- Q3: Storage? -> A: SQLite (see DECISION_LOG DEC-001).

## Test Cases
Maps 1:1 to AC-1..AC-4 above (each becomes a test).

## Decisions
No auth; SQLite storage; text-only notes.
"@

Write-File 'docs/features/001-example-feature/plan.md' @"
# Technical Plan: 001 CRUD Notes

## Summary
Thin Express API -> Service -> SQLite storage. Three endpoints.

## Files to Modify
src/api/notes.*, src/service/notes.*, src/storage/notes.*, tests/*

## Files Not to Touch
.env, docs/ (except updating CODE_INDEX/HANDOFF after work)

## API Contract
- POST /notes {text} -> 201 {id, text, createdAt} | 400
- GET /notes -> 200 [ {id, text, createdAt} ]
- DELETE /notes/{id} -> 204 | 404

## Validation Rules
text required, 1..1000 chars.

## Constitution Gates
- Simplicity: 3 layers only (api/service/storage). OK.
- Anti-Abstraction: use Express + sqlite directly. OK.
- Integration-First: storage contract test before implementation. OK.

## Test Strategy
Unit tests per layer + one integration test hitting the real SQLite file.

## Rollback Plan
Feature branch; revert branch if AC tests fail.

## Docs to Update
CODE_INDEX, DEV_LOG, TEST_REPORT, HANDOFF after each task.
"@

Write-File 'docs/features/001-example-feature/tasks.md' @"
# Tasks: 001 CRUD Notes

## TASK-001 — POST /notes
Status: pending
Trace ID: FEATURE-001/TASK-001
Goal: create a note (AC-1, AC-4)
Files to modify: src/api/notes, src/service/notes, src/storage/notes, tests/*
Verification: unit tests + manual ``POST /notes {""text"":""hi""}`` -> 201
Rollback: revert commit on feature/001-notes

## TASK-002 — GET /notes
Status: pending
Trace ID: FEATURE-001/TASK-002
Goal: list notes (AC-2)
Verification: unit test + manual ``GET /notes`` -> 200 array

## TASK-003 — DELETE /notes/{id}
Status: pending
Trace ID: FEATURE-001/TASK-003
Goal: delete a note (AC-3)
Verification: unit test + manual ``DELETE /notes/1`` -> 204

## /analyze — Cross-Artifact Analysis Gate
- AC-1..AC-4 each map to a task: AC-1,AC-4 -> TASK-001 ; AC-2 -> TASK-002 ; AC-3 -> TASK-003. OK.
- No orphan tasks; no unresolved clarification markers. OK.
- Constitution gates satisfied (see plan.md). OK.
Verdict: consistent — cleared to implement (Phase 6).
"@

# ----------------------------------------------------------------------------
Write-Host ""
Write-Host ("DONE. Scaffold created at: " + $Path) -ForegroundColor Green
Write-Host "Next: run the mechanical check ->" -ForegroundColor Cyan
Write-Host ("  powershell -ExecutionPolicy Bypass -File " + (Join-Path $Path 'scripts/check-consistency.ps1'))
