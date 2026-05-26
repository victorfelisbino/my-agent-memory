# Memory adoption playbook

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Borrowed patterns, opinionated defaults.</h1>
			<p class="lead">Notes on what I copied from other memory projects (mem0, OpenMemory, the cursor-memory-bank line of work) and the operating rules I settled on for this repo. Treat it as a working contract, not gospel &mdash; some of what's below I run today, some of it is still aspirational. See <a href="status.md">Status</a> for the precise line.</p>
			<div class="pill-row">
				<span class="pill">Layer by scope</span>
				<span class="pill">Evidence first</span>
				<span class="pill">Store at value boundaries</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Adopted today</strong>
				<span>Scope classification (private vs shared), ingestion rule (one-verb capture), weekly synthesis cadence.</span>
			</div>
			<div class="kpi-item">
				<strong>On paper only</strong>
				<span>Confidence + last-verified metadata on every entry; retrieval at every decision point.</span>
			</div>
			<div class="kpi-item">
				<strong>Promotion rule</strong>
				<span>Promote only with evidence, reuse, and a transfer test — manual judgement today, no harness yet.</span>
			</div>
		</div>
	</div>
</div>

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Adopt now</span>
		<h3>Scope + ingestion controls</h3>
		<p>Classify memory by scope and reject speculative low-signal entries.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Execution</span>
		<h3>Retrieve at decision points</h3>
		<p>Re-query memory before assumptions, design choices, and commits.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Promotion</span>
		<h3>Evidence before sharing</h3>
		<p>Promote only after repeated reuse with verification metadata.</p>
	</div>
</div>

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

What I actually adopted (and what's still on paper):

1. Layer memory by scope &mdash; **adopted.** Private state lives in a separate repo; shared patterns live here. The split is enforced by `.gitignore` and the resolution order in `_personal-root.ps1`.

2. Add ingestion quality controls &mdash; **partly adopted.** The promotion rule (reusable + evidence + falsifiable + fresh) is documented in [framework-scope.md](framework-scope.md). Confidence and `last_verified` are not yet stamped on every entry; that's a Wave 5 cleanup.

3. Enforce retrieval at decision points &mdash; **manual only.** Today retrieval means running `summon-memory` and pasting the brief. There is no agent integration that retrieves before every assumption / option / commit. Auto-retrieval is roadmap Wave 4-A.

4. Store at value boundaries &mdash; **partly adopted.** `loop.ps1` makes one-verb capture cheap. Discipline about what *not* to capture is still mostly judgement, not enforced.

5. Add no-memory fallback behavior &mdash; **documented.** If `summon-memory` fails, working in plain mode and back-filling later is the policy. No formal fallback path is wired into any agent.

6. Keep token efficiency intentional &mdash; **adopted.** `summon-memory -Compact` exists; the [Copilot auto-mode](copilot-auto-mode.md) page lays out the rule for when to use which mode.

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

!!! danger "These will silently degrade the system"
    1. Retrieve once at task start and never again.
    2. Store everything (memory pollution).
    3. Keep high-confidence wording for unverified facts.
    4. Let old lessons survive without verification date.
    5. Treat memory as a write-only journal rather than decision support.

## Promotion rule (personal → shared)

!!! abstract "All four must be true"
    1. Reusable in at least two future contexts.
    2. Backed by concrete evidence (PR / deploy / incident).
    3. Contains a guardrail that changes behavior.
    4. Has an owner and a verification date.

## Cross-language, CLI, and MCP protocol

To make memory useful across different stacks, every promoted lesson should include these minimum fields:

1. `language`: one or more (e.g., Apex, TypeScript, C#)
2. `runtime`: versioned execution context (e.g., Node 20, .NET 8)
3. `cli_tools`: exact tools used (e.g., sf, git, npm, dotnet)
4. `mcp_servers`: server names if applicable
5. `repro_command`: command that produced the failure/signal
6. `verify_command`: command that proved the fix

Why this matters:
- Language rules drift by runtime version.
- CLI flags and behavior drift by version.
- MCP capabilities vary by server and deployment.

### Retrieval ordering (recommended)

When ranking candidate snippets for a task, prefer this order:

1. Same domain
2. Same language + runtime
3. Same CLI/MCP context
4. Freshness + confidence
5. Evidence links

This ordering is the highest-leverage change for reducing hallucinations on "we have done this many times" tasks.
