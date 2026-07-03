# Request Log

Last updated: 2026-06-05

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
| 2026-06-05 09:00:00 | APPROVED-001 | docs/features/001-example-feature TASK-001..003 (CRUD notes) | user (scaffold) | Q1 auth (no), Q2 max-len (1000), Q3 storage (sqlite) | C-001 single-user | active |

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
### 2026-06-05 — REQ-001 — Build a notes API
User intent summary: store and retrieve short notes via a small API.
Converted into: feature 001-example-feature.
Status: planned.
