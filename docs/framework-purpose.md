# What it does

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Why this exists: the origin story.</h1>
			<p class="lead">This started as one person's daily loop: write down what I learned, only promote a lesson once I've hit it more than once, and surface the relevant pieces back into the next prompt. The quality gate grew out of the same frustration everyone has &mdash; most of what gets "remembered" is noise. The admission gate is the answer to that.</p>
			<div class="pill-row">
				<span class="pill">Capture</span>
				<span class="pill">Synthesize</span>
				<span class="pill">Promote or retire</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Primary output</strong>
				<span>A ranked brief pasted into Copilot before complex tasks, plus a quality gate that filters every write.</span>
			</div>
			<div class="kpi-item">
				<strong>Primary risk reduced</strong>
				<span>Repeating the same mistake because the agent has no memory of the last one &mdash; or having too much noise to find the signal.</span>
			</div>
			<div class="kpi-item">
				<strong>Success signal</strong>
				<span>Fewer back-and-forth turns to land on the right answer; fewer invented file paths and APIs; cleaner memory over time.</span>
			</div>
		</div>
	</div>
</div>

!!! note "What's actually automated vs. manual"
    **Automated:** the admission gate (every candidate scored, junk rejected with a reason), the measurement harness, the dashboard, lint and drift checks in CI. **Manual:** deciding what to promote from your private notes into this shared layer, and pointing your agent's native memory (Copilot memory scopes, CLAUDE.md, Cursor rules) at the curated files here. The original capture/sync/summon pipeline was retired in June 2026 &mdash; editor-native memory does that job now. See [Status](status.md) for the precise line.

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Input</span>
		<h3>Activity + decisions</h3>
		<p>Signals are captured from real execution and review cycles.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Engine</span>
		<h3>Synthesize and validate</h3>
		<p>Only reusable and testable lessons become shared defaults.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Output</span>
		<h3>Fresh guardrails</h3>
		<p>Rules stay current through verification and timed retirement.</p>
	</div>
</div>

## Purpose

- Keep active work and commitments visible across machines.
- Turn incidents and decisions into reusable, verified rules.
- Improve Copilot output with relevant prior context.

## When to use

- When you want a coding agent to remember a generalized lesson the next time the same shape of problem shows up.
- When recurring mistakes signal a missing guardrail.
- When you already keep two kinds of notes (private and shareable) and want a clean split between them.

## Inputs

- Candidate memories from whatever capture path you run (your agent's native memory, your own scripts).
- Lessons promoted from private notes into this repo.

## Outputs

- A keep/reject decision with a reason for every candidate memory (`score_memory.py --score-one`).
- Curated principles, gotchas, and domain playbooks here.

## Operating cycle

1. Gate every candidate memory at write time.
2. Promote only what passes the transfer test (still applies in a language you haven't used yet).
3. Retire or downgrade stale rules.

## Guardrails

!!! abstract "Hard rules for what lands here"
    - Add shared rules only if they are reusable, measurable, and falsifiable.
    - Record confidence and last-verified date for strategic rules.
    - Archive stale guidance when freshness thresholds are missed.
    - These rules are aspirational metadata standards. Today not every page in this repo carries confidence + last-verified — see [Status](status.md). Closing that gap is part of Wave 5.

## Success signals

- Faster state recovery when resuming work.
- Fewer repeated failure patterns.
- Decision logs with follow-up verification.
- Weekly updates that keep guidance current.