# my-agent-memory

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>The shared brain for my AI coding agents.</h1>
			<p class="lead">Two-repo pattern: a private repo holds raw observations, client names, and active project state; <strong>this</strong> repo holds only the generalized lessons, guardrails, and reasoning patterns that survive the promotion bar. Every agent session pulls from here, so the more it learns, the smarter the next session starts &mdash; without leaking anything private.</p>
			<div class="pill-row">
				<span class="pill">Shared layer</span>
				<span class="pill">Promotion-gated</span>
				<span class="pill">No private data</span>
			</div>
			<div class="cta-row">
				<a class="md-button md-button--primary" href="should-you-use-this/">Is this for you?</a>
				<a class="md-button" href="quick-restart-routine/">See the daily routine</a>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Compounds over time</strong>
				<span>Every promoted lesson permanently raises the floor for the next session, across machines and projects.</span>
			</div>
			<div class="kpi-item">
				<strong>Private stays private</strong>
				<span>A hard boundary keeps client names, active state, and project-specific notes in the personal repo, never here.</span>
			</div>
			<div class="kpi-item">
				<strong>Copilot starts informed</strong>
				<span><code>summon-memory</code> pulls the most relevant generalized lessons + router hints into every prompt.</span>
			</div>
		</div>
	</div>
</div>

## How the two repos fit together

<div class="bento-grid">
	<div class="bento-card wide">
		<span class="meta">01 / Private repo (yours)</span>
		<h3>Raw signal lives here</h3>
		<p>Observations as you work, client and project names, decision journal, active threads, goals, anything specific to what you're shipping today. Never leaves your machine.</p>
	</div>
	<div class="bento-card wide">
		<span class="meta">02 / This repo (shared)</span>
		<h3>Generalized lessons only</h3>
		<p>A pattern only lands here once it has been hit more than once, generalized past the specific project, and verified. Reasoning principles, gotchas, domain playbooks, anti-hallucination rules, router hints.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">03 / The promotion gate</span>
		<h3>What earns a place here</h3>
		<p>Reusable across projects, measurable, falsifiable, and fresh. If a lesson fails any of the four, it stays in the private repo.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">04 / The agent loop</span>
		<h3>How it gets smarter</h3>
		<p><code>summon-memory</code> reads from this repo every session, injects relevant lessons + router hints + anti-hallucination context, so each new prompt starts on top of everything already learned.</p>
	</div>
</div>

## Honest scope

!!! note "What this is and isn't"
    This is the public, shared layer of one person's two-repo memory pattern. There are no customers, no production metrics, no team consuming it &mdash; just me, running it daily and tightening it weekly so my own agents stay sharp across projects. The category is crowded (mem0, OpenMemory, cursor-memory-bank, memory-bank-mcp). If you want a polished product or hosted service, use one of those. The specific thing on offer here is the **separation pattern**: keep private signal in a private repo, promote only generalized lessons into a shared brain the agent reads from every session.

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
</div>
