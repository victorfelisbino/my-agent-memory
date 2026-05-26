# my-agent-memory

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>A brain that learns once and carries it forward.</h1>
			<p class="lead">A senior developer picks up a new language faster than a beginner not because they remember more syntax, but because the <em>principles</em> transfer: scope, state, error boundaries, naming, debugging instincts. This repo is that for an AI coding agent. Project-specific facts stay in a private repo and get forgotten. Generalized principles graduate into this shared brain and stay forever, so every new session starts with years of compounded expertise instead of from scratch.</p>
			<div class="pill-row">
				<span class="pill">Transferable principles</span>
				<span class="pill">Promotion-gated</span>
				<span class="pill">Compounds over time</span>
			</div>
			<div class="cta-row">
				<a class="md-button md-button--primary" href="should-you-use-this/">Is this for you?</a>
				<a class="md-button" href="principles-ways-of-thinking/">See the principles</a>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Principles, not facts</strong>
				<span>Only patterns that transfer across languages, frameworks, and projects earn a place here. Facts stay private and get forgotten on purpose.</span>
			</div>
			<div class="kpi-item">
				<strong>Pattern recognition compounds</strong>
				<span>The 50th gotcha promoted is more valuable than the 1st &mdash; because by then the agent recognizes the <em>shape</em> of the problem before it asks.</span>
			</div>
			<div class="kpi-item">
				<strong>Every session starts senior</strong>
				<span><code>summon-memory</code> injects the relevant principles, gotchas, and guardrails into the prompt &mdash; so a new project never starts at zero.</span>
			</div>
		</div>
	</div>
</div>

## How human expertise works — and how this mirrors it

<div class="bento-grid">
	<div class="bento-card wide">
		<span class="meta">01 / Episodic (private repo)</span>
		<h3>What happened, with names attached</h3>
		<p>Raw observations as you work, client and project names, the specific bug on the specific Tuesday. Like episodic memory: vivid but local, mostly forgotten within months. Lives only in the private repo.</p>
	</div>
	<div class="bento-card wide">
		<span class="meta">02 / Semantic (this repo)</span>
		<h3>The pattern, stripped of the story</h3>
		<p>Once the same shape shows up more than once, it gets distilled to a principle and graduates here. Like semantic memory: "async state in any UI framework leaks if you don't cancel on unmount" survives long after you forget which project taught you that.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">03 / The promotion gate</span>
		<h3>Transfer test before promotion</h3>
		<p>A lesson only lands here if it would still apply in a language or framework you haven't used yet. Reusable, measurable, falsifiable, fresh. If it fails the transfer test, it stays private.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">04 / Compounding intuition</span>
		<h3>Year 1 vs year 10</h3>
		<p>A junior with 50 facts loses to a senior with 50 principles every time. The shared brain is built so the agent ages like a senior dev: fewer surprises, faster pattern matches, better defaults &mdash; even on stacks it has never touched.</p>
	</div>
</div>

## Honest scope

!!! note "What this is and isn't"
    This is one person's working version of that idea: the shared, semantic layer of a two-repo memory pattern. There are no customers, no production metrics, no team consuming it &mdash; just me running it daily and tightening it weekly so my own agents age into seniority instead of resetting every session. The memory category is crowded (mem0, OpenMemory, cursor-memory-bank, memory-bank-mcp); if you want a polished product or hosted service, use one of those. The specific thing on offer here is the **transfer-test pattern**: keep episodic signal private, promote only what survives the "would this still apply in a language you haven't met yet?" test, and let agents read from the result.

!!! warning "Status, in one paragraph"
    Today this repo is a curated set of patterns and scripts, not a framework. Several of the most interesting ideas &mdash; auto-injected anti-hallucination, transfer-test promotion, router-hints loop &mdash; are documented but not yet shipped end-to-end. See [Status](status.md) for the real/documented/planned breakdown and the [Roadmap](roadmap.md) for the waves that turn the documented things into shipped things.

## Pages worth reading

<div class="bento-grid">
	<a class="bento-card tall" href="framework-purpose/">
		<span class="meta">Foundation</span>
		<h3>What it does</h3>
		<p>The actual purpose, in plain language, and how I tell whether it is working.</p>
	</a>
	<a class="bento-card tall" href="framework-scope/">
		<span class="meta">Boundary</span>
		<h3>What stays private</h3>
		<p>What I commit to this repo and what stays on my disk only.</p>
	</a>
	<a class="bento-card tall" href="memory-adoption-playbook/">
		<span class="meta">Mechanics</span>
		<h3>Memory adoption playbook</h3>
		<p>How lessons get promoted, when they get retired, and the rules that keep the file set from rotting.</p>
	</a>
	<a class="bento-card full" href="principles-ways-of-thinking/">
		<span class="meta">Reasoning</span>
		<h3>Principles and ways of thinking</h3>
		<p>The reusable reasoning patterns, decision rules, and bias checks underneath the rest. No company or project data &mdash; just the thinking.</p>
	</a>
	<a class="bento-card tall" href="copilot-auto-mode/">
		<span class="meta">Copilot</span>
		<h3>Copilot auto-mode</h3>
		<p>The router-hints trick and the two brief sizes I use to keep auto-mode from drifting.</p>
	</a>
	<a class="bento-card tall" href="memory-ecosystem-research-2026-05-15/">
		<span class="meta">Notes</span>
		<h3>Memory ecosystem research</h3>
		<p>Patterns I borrowed from existing memory frameworks and what I deliberately chose not to copy.</p>
	</a>
	<a class="bento-card tall" href="status/">
		<span class="meta">Reality check</span>
		<h3>Status</h3>
		<p>What's real today, what's documented-only, what's planned. The single source of truth for what actually works.</p>
	</a>
	<a class="bento-card tall" href="roadmap/">
		<span class="meta">Direction</span>
		<h3>Roadmap</h3>
		<p>Six waves from honest baseline to a real guardrail layer for coding agents. Each wave has a kill switch.</p>
	</a>
</div>
