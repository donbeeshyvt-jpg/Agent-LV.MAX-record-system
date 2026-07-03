# Requirements / Constitution

Last updated: 2026-06-05

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
