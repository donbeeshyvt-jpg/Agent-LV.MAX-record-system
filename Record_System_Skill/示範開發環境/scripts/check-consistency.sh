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