# evidence

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Numbers, not vibes.</h1>
			<p class="lead">The admission gate was built iteratively over 14 iterations with honest before/after numbers at every step. Every claim below is reproducible from this repo's CI.</p>
			<div class="pill-row">
				<span class="pill">100/100/100 on v4</span>
				<span class="pill">1.0% real-corpus rejection</span>
				<span class="pill">CI-enforced parity</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>100% accuracy</strong>
				<span>On a 100-item labeled fixture (50 keep, 50 reject). Every item classified correctly.</span>
			</div>
			<div class="kpi-item">
				<strong>1.0% real-corpus rejection</strong>
				<span>4 of 381 items from actual memory files. All 4 defensible (status snapshots, imperative-only TODOs).</span>
			</div>
			<div class="kpi-item">
				<strong>Zero false positives</strong>
				<span>No good memory was incorrectly rejected on either the fixture or the real corpus.</span>
			</div>
		</div>
	</div>
</div>

## Fixture methodology

The labeled fixture contains **100 items**: 50 labeled "keep" and 50 labeled "reject."

**Keep items** are sourced from real curated memories — gotchas, domain rules, cross-language principles, tool quirks, and debugging patterns that would genuinely help a future session.

**Reject items** are sourced from documented junk categories (mem0 issue #4573, real production garbage, auto-capture noise). Each reject has a category label explaining why it's junk.

The fixture was built iteratively:

| Version | Items | Accuracy | Good recall | Junk recall |
|---------|-------|----------|-------------|-------------|
| v1 (baseline) | 20 | 75% | 100% | 50% |
| v1 (iter 2) | 20 | 95% | 100% | 90% |
| v1 (iter 3) | 20 | 100% | 100% | 100% |
| v2 (iter 4) | 40 | 95% | 100% | 90% |
| v2 (iter 5) | 40 | 100% | 100% | 100% |
| v3 (iter 6) | 60 | 100% | 100% | 100% |
| v4 (iter 7) | 100 | 91% | 100% | 82% |
| v4 (iter 8) | 100 | **100%** | **100%** | **100%** |

Each growth step deliberately introduces harder cases that break the existing rules. New rules are added only when a miss is identified, not speculatively. No rule was added without a corresponding fixture item that fails without it.

## Before/after examples

### Rejected (correctly)

<div class="bento-grid">
	<div class="bento-card tall">
		<span class="meta">Rejected / boot-noise</span>
		<h3>"Session started 2026-05-26 at 09:00 on office-pc."</h3>
		<p><strong>Score:</strong> -0.7 &mdash; <strong>Reason:</strong> reusability=-1 (timestamp + machine name = transient, never useful in a future session)</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Rejected / vague</span>
		<h3>"Code quality matters and we should care about it."</h3>
		<p><strong>Score:</strong> -0.2 &mdash; <strong>Reason:</strong> actionability=-1 (vague truism, no specific behavior change)</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Rejected / self-referential</span>
		<h3>"Agent answered the user's question with confidence today."</h3>
		<p><strong>Score:</strong> -0.7 &mdash; <strong>Reason:</strong> reusability=-1 (self-referential, no transferable knowledge)</p>
	</div>
</div>

### Kept (correctly)

<div class="bento-grid">
	<div class="bento-card tall">
		<span class="meta">Kept / gotcha</span>
		<h3>"Avalonia DataGrid is a separate NuGet package; must dotnet add package Avalonia.Controls.DataGrid before using it."</h3>
		<p><strong>Score:</strong> 0.85 &mdash; Reusable across sessions, atomic, actionable (prevents a specific failure).</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Kept / principle</span>
		<h3>"Never accept 'done' claims without independent verification: build success, targeted tests, and requirement-by-requirement pass/fail."</h3>
		<p><strong>Score:</strong> 1.1 &mdash; Cross-language principle, transfers to any project, changes behavior.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Kept / domain-rule</span>
		<h3>"Salesforce: always check field-level security after an Apex deploy; profile/permset changes do not deploy automatically with classes."</h3>
		<p><strong>Score:</strong> 1.1 &mdash; Domain-specific but reusable across every Salesforce project.</p>
	</div>
</div>

## Real-corpus validation

Beyond the labeled fixture, the scorer runs against **381 items** extracted from actual memory files in production use. This is the "does it work on real data, not just test data" check.

**Result:** 4 items rejected (1.0%). All defensible:

- 1 status snapshot (`Status: deployed to staging`)
- 3 personal-goal TODO bullets from `goals.md` (imperative-only-short: "Ship Wave 3", "Review PR", "Update docs")

Zero false positives — no curated principle, gotcha, or domain rule was rejected.

## Cross-language parity

The same scoring rules exist in two implementations:

- [`admission-gate/score-memory.ps1`](https://github.com/victorfelisbino/my-agent-memory/blob/main/admission-gate/score-memory.ps1) (PowerShell, the original)
- [`admission-gate/score_memory.py`](https://github.com/victorfelisbino/my-agent-memory/blob/main/admission-gate/score_memory.py) (Python port, for middleware use)

CI runs a parity check on every PR: same fixture in, same per-item keep/reject decision out. A one-sided rule change fails the build. This covers:

- v4 fixture (100 items, no store)
- v5 fixture (108 items, with `--store`)
- v6 fixture (116 items, with `--store` + `--recalled`)
- Real-memory corpus (381 items, all flag combinations)

## Honest limitations

What the gate does NOT do today:

- **No embedding-based similarity.** Contradiction and feedback-loop detection use polarity + subject-overlap heuristics. Paraphrased contradictions with no shared content tokens may slip through.
- **No temporal/staleness scoring.** Memories don't decay over time yet. A stale fact scores the same as a fresh one.
- **Conservative threshold.** The gate favors keeping over rejecting on borderline cases. This is deliberate — false rejections (losing a good memory) are worse than false keeps (storing a marginal one).
- **No semantic understanding.** The scorer is pattern-based, not LLM-powered. It catches structural junk reliably but can't evaluate whether a claim is factually correct.

These limitations are acknowledged, not bugs. The goal is a fast, deterministic, embeddable filter — not a replacement for human curation.
