# Memory Adoption Playbook (From External Projects)

This file distills what is useful from:

- mem0ai/mem0
- CaviraOSS/OpenMemory
- vanzan01/cursor-memory-bank
- alioshr/memory-bank-mcp
- groupzer0/vs-code-agents

Use it as an implementation guide for this repository.

## What they are doing (practical summary)

1. mem0: Layered memory model and controlled ingestion.
2. OpenMemory: Local-first memory engine with MCP tooling and dual memory systems.
3. cursor-memory-bank: Token-efficient workflow memory with phased context handoffs.
4. memory-bank-mcp: Strict file lifecycle and pre-flight validation before task execution.
5. vs-code-agents: Memory contract with explicit retrieval/store triggers and anti-patterns.

## What we should adopt immediately

1. Layer memory by scope
- General rule: classify each lesson as one of `session`, `user`, or `org/domain` scope.
- Why: avoids over-retrieval and irrelevant context.

2. Add ingestion quality controls
- Store only reusable, evidence-backed facts.
- Mark confidence (`low|medium|high`) and `last_verified` date.
- Reject speculative statements unless explicitly marked as hypothesis.

3. Enforce retrieval at decision points
- Retrieve memory before assumptions, option selection, or implementation.
- Retrieval query should be hypothesis-driven (specific question), not generic.

4. Store at value boundaries
- Store after non-trivial progress, decisions, dead ends, and discovered constraints.
- Do not store chat filler, trivial acknowledgments, or duplicate notes.

5. Add no-memory fallback behavior
- If memory tooling fails, explicitly switch to no-memory mode.
- Record decisions in working docs with extra detail, then backfill memory later.

6. Keep token efficiency intentional
- Use short summaries first, detail-on-demand second.
- Preserve only critical handoff context across phases.

## Suggested operating contract for this repo

Before task execution:
1. Run `summon-memory` for the active task.
2. Read top snippets.
3. If uncertainty remains, run one more targeted retrieval query.

During execution:
1. Re-retrieve when making assumptions or design choices.
2. Track decisions and rationale with stable identifiers (file paths, PR id, deploy id).

After execution:
1. Store one concise, reusable lesson.
2. Add confidence and verification metadata.
3. Promote to `gotchas.md` or domain playbook only if reusable.

## Anti-patterns to avoid

1. Retrieve once at task start and never again.
2. Store everything (memory pollution).
3. Keep high-confidence wording for unverified facts.
4. Let old lessons survive without verification date.
5. Treat memory as write-only journal rather than decision support.

## Promotion rule (personal -> shared)

Promote a lesson to shared/domain docs only if all are true:

1. Reusable in at least two future contexts.
2. Backed by concrete evidence (PR/deploy/incident).
3. Contains a guardrail that changes behavior.
4. Has owner and verification date.
