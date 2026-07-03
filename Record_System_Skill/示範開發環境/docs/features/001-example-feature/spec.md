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
- Q1: Auth required? -> A: No. Single-user, decided 2026-06-05 (constraint C-001).
- Q2: Max note length? -> A: 1000 chars; longer returns 400.
- Q3: Storage? -> A: SQLite (see DECISION_LOG DEC-001).

## Test Cases
Maps 1:1 to AC-1..AC-4 above (each becomes a test).

## Decisions
No auth; SQLite storage; text-only notes.
