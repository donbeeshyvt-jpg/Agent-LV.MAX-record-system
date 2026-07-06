# Agent-LV.MAX (record-system)

[繁體中文](README.md) | English

> **Agent Collaboration & Record System: Multi-Role × Planning Records × Loop Engineering**
> Three composable skills that give any AI real discipline: think first, prove it before calling something done, and leave records so the next handoff picks up cleanly. Use them standalone or interlocked; local or smaller models especially get close to commercial-agent quality.
>
> - **Multi-Role** → [`Agent_OS_Skill`](Agent_OS_Skill/): a 12-role multi-agent operating system (how to think)
> - **Planning & Records** → [`Record_System_Skill`](Record_System_Skill/): development governance & handoff records (how to never forget)
> - **Loop Engineering** → [`Loop_Engineering_Skill`](Loop_Engineering_Skill/): planning controlled, self-running loops (how to keep going)
>
> Everything is pure-Markdown procedural skills: paste a system prompt and go. Not bound to any specific tool or framework; missing capabilities degrade honestly instead of being faked.

> **Language note**: the skill contents (prompts, role files, templates) are written in Traditional Chinese. Modern LLMs follow them fine regardless of your conversation language; ask your model to respond in English if preferred.

---

## The Three Skills

| Skill | One-liner | Entry file |
| --- | --- | --- |
| [Agent_OS_Skill](Agent_OS_Skill/) | **12-role multi-agent OS**: intent decoding → decomposition → multi-lens research → proposals → minimal-change implementation → debugging → red-team → evidence-based acceptance → synthesis → curation. One baton at a time, with evidence, fully traceable. Includes a cross-cutting **judgment layer** (task-start 3 questions, Proof Contract, rationalization-excuse table). | `Agent_OS_Skill/SKILL.md` |
| [Loop_Engineering_Skill](Loop_Engineering_Skill/) | **Multi-loop engineering planning**: turn recurring work into a fleet of controlled, self-running loops — 12 loop patterns, persistent STATE memory, maker/checker verification, human gates, budget circuit breakers, and an L1→L2→L3 autonomy ladder. | `Loop_Engineering_Skill/SKILL.md` |
| [Record_System_Skill](Record_System_Skill/) | **Development governance & handoff**: `AGENTS.md` as the single entry + `docs/` as external memory (conversation log, handoff, tasks, approval workflow). AI development becomes continuous, traceable, and amnesia-free across agents — while saving tokens. | `Record_System_Skill/README.md` |

## Using Each Skill Standalone

**Agent_OS_Skill only** — make a model behave like an agent on one-shot tasks:
1. Copy the "★ Master System Prompt" block from `Agent_OS_Skill/SKILL.md` and paste it as your system prompt. Give it a task.
2. For small local models: unconditionally prepend `reference/01` (the execution-discipline block — the highest-leverage piece); with tiny context windows, run only the 4-role slim path.
3. You can also use a single role: every file in `roles/01`–`12` has its own paste-ready system prompt (judgment layer already embedded).

**Loop_Engineering_Skill only** — turn repetitive work into controlled automation:
1. Paste the "★ Master System Prompt" from `Loop_Engineering_Skill/SKILL.md`, describe your project, and it produces a **Loop Engineering Plan** (the 12 roles are summarized inline, so it runs without Agent_OS installed).
2. Put the generated `LOOP-NNN.md` / `STATE-NNN.md` / `LOOP_PORTFOLIO.md` into your project (`loops/` at the repo root if you don't use the docs structure).
3. Works without any scheduler: it degrades to a "manual restart checklist" — wake the agent, it reads STATE, and continues. Iron rule: every loop is born L1 report-only; upgrades require human approval.

**Record_System_Skill only** — make any project handoff-able and amnesia-free:
1. Run `建立開發環境.ps1` to scaffold the `docs/` governance skeleton (or copy from `示範開發環境/`, the working example).
2. First message to any new agent: *"Read `AGENTS.md` and `docs/` (HANDOFF, CONVERSATION_LOG, TASKS, CODE_INDEX) first. Do not scan the entire codebase."*
3. See that folder's `README.md` for details.

## Using Them Together (soft detection, graceful degradation)

```
User task
   │
   ▼
Agent_OS (engine) ─ Context intake: detects the record-system structure
   │                → reads docs/ conversation history to continue prior thinking (no hooks required)
   │
   ├─ One-shot task → 12-role relay → deliver
   │
   └─ NEEDS_LOOP flag (recurring work) → loads Loop_Engineering_Skill
            │
            ▼
      Loop Engineering Plan → governance files live in the record system's docs/loops/
      → human approval (APPROVED) → go live
```

- The three packages only **soft-detect** each other (prompt-driven: the AI actively looks and reads). No hard dependency: each package is fully usable alone; when a companion is absent, each follows its own degradation rules.
- Interlock details: `Agent_OS_Skill/reference/04` (reading the record system) and the `NEEDS_LOOP` row in `Agent_OS_Skill/reference/02` (triggering loop engineering).

## Shared Design Principles

- **Soft, prompt-driven**: installs nothing, depends on no hooks or schedulers; missing capabilities are honestly labeled "needs manual follow-up".
- **Evidence first**: never say *done* without running it; default verdict is NEEDS WORK; numbers beat adjectives.
- **Human in the loop**: high-risk actions pass a human gate; automation is born report-only and needs approval to level up.
- **Files are memory**: state lives in documents, not in the conversation — switch models, tools, or sessions and pick up where you left off.

## License

MIT — see [LICENSE](LICENSE).
