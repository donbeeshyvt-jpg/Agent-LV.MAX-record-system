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
