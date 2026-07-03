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
