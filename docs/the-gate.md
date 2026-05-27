# the gate

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Four dimensions. One decision. Keep or reject.</h1>
			<p class="lead">Every candidate memory passes through a scoring pipeline. Four dimensions are evaluated independently, summed to a total score, and compared against a threshold. Below the line = rejected with a reason. Above = kept and appended.</p>
			<div class="pill-row">
				<span class="pill">Reusability</span>
				<span class="pill">Atomicity</span>
				<span class="pill">Novelty</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>40+ rules</strong>
				<span>Pattern-matched across junk categories sourced from real production failures.</span>
			</div>
			<div class="kpi-item">
				<strong>Two scorers, identical decisions</strong>
				<span>PowerShell and Python ports. CI enforces parity on every PR.</span>
			</div>
			<div class="kpi-item">
				<strong>Exit code contract</strong>
				<span>0 = keep, 3 = reject. Pipe into any capture pipeline.</span>
			</div>
		</div>
	</div>
</div>

## Architecture

```
candidate memory (JSON)
    │
    ▼
┌─────────────────────────────┐
│  score_memory.py --score-one │
│                              │
│  ┌─────────┐  ┌──────────┐  │
│  │Reusabil.│  │ Atomicity│  │
│  └────┬────┘  └────┬─────┘  │
│       │             │        │
│  ┌────┴────┐  ┌────┴─────┐  │
│  │ Novelty │  │Actionabil│  │
│  └────┬────┘  └────┬─────┘  │
│       │             │        │
│       ▼             ▼        │
│     total = sum(dimensions)  │
│       │                      │
│       ▼                      │
│   total >= 0.5? ─── no ───▶ REJECT (exit 3)
│       │                      │
│      yes                     │
│       │                      │
│       ▼                      │
│     KEEP (exit 0)            │
└─────────────────────────────┘
    │                    │
    ▼                    ▼
observations.jsonl    observations.rejected.jsonl
                      (with reason)
```

## The four scoring dimensions

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Dimension 1</span>
		<h3>Reusability</h3>
		<p>Would this help in a future session on a different project? Penalizes timestamps, machine names, specific file paths, sprint references, named persons, and transient state. Rewards cross-language patterns and transferable principles.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Dimension 2</span>
		<h3>Atomicity</h3>
		<p>Is this one discrete fact or a compound paragraph? Multi-sentence memories with mixed concerns get penalized. The ideal memory is one actionable statement.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Dimension 3</span>
		<h3>Novelty</h3>
		<p>Does the store already know this? Contradiction detection flags conflicting claims. Feedback-loop prevention blocks recalled memories from being re-ingested as "new."</p>
	</div>
</div>

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Dimension 4</span>
		<h3>Actionability</h3>
		<p>Does this change behavior? Vague truisms ("code quality matters"), empty agreements ("ok sounds good"), self-praise, and greetings score zero or negative. Specific practices and gotchas score positive.</p>
	</div>
</div>

## Contradiction detection

When you pass a `--store` file (JSONL of existing memories), the scorer extracts the **subject** and **polarity** from both the candidate and every store entry:

- **Subject:** content words after removing stopwords
- **Polarity:** positive (+) for "always/prefer/use", negative (-) for "never/avoid/don't"

If the candidate shares significant subject overlap with a store entry AND has the opposite polarity, the novelty dimension takes a -2.0 penalty — pushing the total below threshold.

```bash
# Example: store says "always use strict mode"
# Candidate says "never use strict mode"
# → contradiction detected, candidate rejected
echo '{"text":"Never use strict mode in production."}' \
  | python3 score_memory.py --score-one --store store.jsonl
# exit 3: reject (reason: contradiction-against-store)
```

## Feedback-loop prevention

The failure mode: an agent recalls a memory, includes it in its response, then the capture system extracts it as a "new" observation. Repeat 668 times (documented in mem0).

When you pass a `--recalled` file (JSONL of memories recalled in the current session), the scorer checks whether the candidate overlaps significantly with any recalled item. Same subject + same polarity + 4+ shared content tokens = feedback loop detected.

```bash
echo '{"text":"Always validate input at system boundaries."}' \
  | python3 score_memory.py --score-one --recalled session.jsonl
# If this exact principle was recalled earlier → reject
```

## Junk categories the rules cover

The 50 reject fixtures span these documented categories:

| Category | Example |
|----------|---------|
| Boot noise | "Session started 2026-05-26 at 09:00 on office-pc." |
| Transient state | "Currently reading file src/foo.ts at line 42." |
| Hallucinated profile | "User is named John, works at Acme Corp." |
| Vague truism | "Code quality matters and we should care about it." |
| Self-referential | "Agent answered the user's question with confidence." |
| Compound blob | Multi-sentence mixed concerns |
| Status ping | "Deploy completed at 14:32." |
| Greeting/sign-off | "Thanks!" / "Let me know if you need anything." |
| Self-praise | "I provided an excellent solution." |
| Task restatement | Repeating what the user just asked |
| Pop-culture reference | Non-technical content |
| Confidence-only | "I'm 95% sure this is correct." |
| Empty agreement | "ok sounds good" |

## Integration

The scorer exposes a simple contract:

```bash
# Single-item scoring (pipe mode)
echo '{"text":"..."}' | python3 score_memory.py --score-one
# stdout: JSON with decision, score, dimensions, reason
# exit 0 = keep, exit 3 = reject

# Batch scoring (fixture mode)
python3 score_memory.py --fixture memories.jsonl --fail-under 85

# With contradiction detection
python3 score_memory.py --score-one --store existing-memories.jsonl

# With feedback-loop prevention
python3 score_memory.py --score-one --recalled session-recalls.jsonl

# Audit logging
python3 score_memory.py --score-one --log-to scoring-log.jsonl
```
