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
    **Automated:** capture from local Copilot transcripts, cross-machine sync of the personal repo, brief generation, weekly synthesis, lint checks. **Manual:** pasting the brief into the Copilot prompt, deciding what to promote from the personal repo into this one, running the weekly review. See [Status](status.md) for the precise line between the two.

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

- Captured activity and decisions (auto from Copilot transcripts; one-verb manual via `loop.ps1`).
- Weekly synthesis outputs.
- Lessons promoted from the personal repo into this one.

## Outputs

- A ranked context brief on demand (`summon-memory`).
- Curated principles, gotchas, and domain playbooks here.
- Weekly synthesis files in the personal repo.

## Operating cycle

1. Capture activity and decisions continuously.
2. Synthesize patterns on a weekly cadence.
3. Promote only what passes the transfer test (still applies in a language you haven't used yet).
4. Retire or downgrade stale rules.

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