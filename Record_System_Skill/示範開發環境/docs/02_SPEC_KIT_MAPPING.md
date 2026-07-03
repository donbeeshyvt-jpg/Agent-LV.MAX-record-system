# Spec Kit Mapping

Last updated: 2026-06-05

Where each Spec-Driven Development artifact lives in this repo.

| Spec Kit command | Artifact | Location here |
|---|---|---|
| /constitution | governing principles | docs/REQUIREMENTS.md + docs/GOLDEN_RULES.md |
| /specify | spec.md | docs/features/NNN-*/spec.md |
| /clarify | Clarifications section | docs/features/NNN-*/spec.md |
| /plan | plan + supporting docs | docs/features/NNN-*/plan.md |
| /tasks | task list | docs/features/NNN-*/tasks.md |
| /analyze | consistency report | note in tasks.md / docs/SELF_CHECK.md |
| /implement | code + tests | src/ + tests/ |

If the real Spec Kit CLI is installed, its `specs/{feature}/` layout is the
equivalent of `docs/features/NNN-*/` here. Keep this file current.
