# Golden Rules

Last updated: 2026-06-05

> Canonical patterns every agent must replicate. Backed by a check where possible.

| ID | Rule | Good example | Bad example | Enforced by (check) |
|---|---|---|---|---|
| GR-001 | All required docs must exist | full docs/ set | missing HANDOFF | scripts/check-consistency.ps1 |
| GR-002 | No unresolved clarification markers in specs | clarified spec | open marker left in spec | scripts/check-consistency.ps1 |
| GR-003 | CODE_INDEX tracks code changes | index updated with code | stale index | scripts/check-consistency.ps1 |
| GR-004 | Code comments in 繁體中文; identifiers in English | `// 處理登入授權` | `// handle login` or Simplified | scripts/check-consistency.ps1 |
| GR-005 | CODE_INDEX bilingual (EN + 繁中職責) | row has both columns | EN-only or 繁中-only | scripts/check-consistency.ps1 |
| GR-006 | Zero Simplified Chinese anywhere | 繁體 `倉庫`、`執行` | (any Simplified equivalent — the check will name it) | scripts/check-consistency.ps1 |

## Notes
New code must follow these. Drift is logged in docs/ENTROPY_LOG.md.
A rule that matters but has no check yet is a TODO: add the check.
