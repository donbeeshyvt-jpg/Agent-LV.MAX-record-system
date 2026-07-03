# Tasks: 001 CRUD Notes

## TASK-001 — POST /notes
Status: pending
Trace ID: FEATURE-001/TASK-001
Goal: create a note (AC-1, AC-4)
Files to modify: src/api/notes, src/service/notes, src/storage/notes, tests/*
Verification: unit tests + manual `POST /notes {""text"":""hi""}` -> 201
Rollback: revert commit on feature/001-notes

## TASK-002 — GET /notes
Status: pending
Trace ID: FEATURE-001/TASK-002
Goal: list notes (AC-2)
Verification: unit test + manual `GET /notes` -> 200 array

## TASK-003 — DELETE /notes/{id}
Status: pending
Trace ID: FEATURE-001/TASK-003
Goal: delete a note (AC-3)
Verification: unit test + manual `DELETE /notes/1` -> 204

## /analyze — Cross-Artifact Analysis Gate
- AC-1..AC-4 each map to a task: AC-1,AC-4 -> TASK-001 ; AC-2 -> TASK-002 ; AC-3 -> TASK-003. OK.
- No orphan tasks; no unresolved clarification markers. OK.
- Constitution gates satisfied (see plan.md). OK.
Verdict: consistent — cleared to implement (Phase 6).
