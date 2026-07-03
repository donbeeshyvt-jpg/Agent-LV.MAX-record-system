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
