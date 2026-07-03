# Decision Log

## 2026-06-05 — DEC-001 — Use SQLite for storage
Context: single-user notes, no scale needs.
Decision: SQLite (boring, stable API, agent-readable).
Alternatives: Postgres (overkill), in-memory (not durable).
Rollback: swap storage layer behind the Service interface.
