# my-agent-memory

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>My working setup for keeping AI coding agents grounded.</h1>
			<p class="lead">This is the personal toolkit I use to stop Copilot from forgetting what I already learned. Markdown files, a few PowerShell scripts, and a weekly review that I actually run. Take any piece that looks useful; ignore the rest.</p>
			<div class="pill-row">
				<span class="pill">Personal, not a product</span>
				<span class="pill">Markdown + scripts</span>
				<span class="pill">Opinionated</span>
			</div>
			<div class="cta-row">
				<a class="md-button md-button--primary" href="should-you-use-this/">Is this for you?</a>
				<a class="md-button" href="quick-restart-routine/">See the daily routine</a>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Resume work fast</strong>
				<span>Open loops and active threads live in plain files, so I pick up where I stopped instead of rebuilding context in my head.</span>
			</div>
			<div class="kpi-item">
				<strong>Stop repeating mistakes</strong>
				<span>A weekly review promotes only patterns I have hit more than once and retires the ones that go stale.</span>
			</div>
			<div class="kpi-item">
				<strong>Copilot starts informed</strong>
				<span><code>summon-memory</code> injects the most relevant lessons and router hints at the top of the prompt so auto-mode picks a sensible model.</span>
			</div>
		</div>
	</div>
</div>

## What's actually in here

<div class="bento-grid">
	<div class="bento-card wide">
		<span class="meta">01 / The artifact</span>
		<h3>Markdown files I write to as I work</h3>
		<p>Decisions, gotchas, observations, a goals file, domain playbooks. Nothing fancy &mdash; just text I can grep, diff, and feed back to the agent.</p>
	</div>
	<div class="bento-card wide">
		<span class="meta">02 / The glue</span>
		<h3>PowerShell + bash scripts</h3>
		<p><code>summon-memory</code> assembles a context brief. <code>capture-observation</code> appends signals. <code>learn-memory</code> and <code>synthesize-observations</code> roll them up. Cross-platform, no services to run.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">03 / The discipline</span>
		<h3>A weekly review that actually happens</h3>
		<p>Without the cadence the rest is dead weight. The scoreboard exists so I notice when I stop running it.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">04 / The Copilot bit</span>
		<h3>Router hints + anti-hallucination context</h3>
		<p>Each brief carries a small header that nudges Copilot auto-mode toward the right model, plus a guardrail doc that cuts retries caused by invented paths and APIs.</p>
	</div>
</div>

## Honest scope

!!! note "Read this before deciding to copy any of it"
    This is one person's working setup. There are no customers, no production metrics, no team adopting it &mdash; just me using it daily and tightening it weekly. The category is crowded (mem0, OpenMemory, cursor-memory-bank, memory-bank-mcp). If you want a polished product, use one of those. If you want to see *how* someone wires memory + governance into their day, pieces here may be useful.

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
