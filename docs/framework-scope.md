# What stays private

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>What goes in the repo, what stays on disk.</h1>
			<p class="lead">This page is the rule I check against before committing anything. Reusable patterns and generalized lessons are public; personal active state, client names, and anything project-specific stays local.</p>
			<div class="pill-row">
				<span class="pill">Scope discipline</span>
				<span class="pill">Privacy boundary</span>
				<span class="pill">Promotion quality gate</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Never commit</strong>
				<span>Personal active-state files and private operational logs.</span>
			</div>
			<div class="kpi-item">
				<strong>Promote only when</strong>
				<span>Reusable, measurable, falsifiable, and fresh.</span>
			</div>
			<div class="kpi-item">
				<strong>Contributor rule</strong>
				<span>Person-specific and short-lived context stays out of shared repo.</span>
			</div>
		</div>
	</div>
</div>

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Belongs here</span>
		<h3>Reusable shared guidance</h3>
		<p>Rules and playbooks that work across people, projects, and tools.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Never here</span>
		<h3>Personal active state</h3>
		<p>Private logs and person-specific working memory stay out.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Gate</span>
		<h3>4-part quality bar</h3>
		<p>Reusable, measurable, falsifiable, and fresh or it does not ship.</p>
	</div>
</div>

## Purpose

- Define what belongs in this shared framework repository.
- Prevent personal/private data from entering shared memory.
- Keep shared guidance reusable and current.

## When to use

- Before opening a pull request.
- Before adding new lessons, rules, or strategy notes.
- During weekly review when pruning or promoting knowledge.

## What this repo is (today)

- The shared, semantic half of a two-repo memory split &mdash; the part safe to commit and read from publicly.
- A working set of reusable rules, playbooks, scripts, and lessons that have survived a transfer-test.
- A decision and learning layer that favors measurable rules over opinion-only notes.
- A capture/synthesis/promotion/prune loop, run by one person on a weekly cadence.

## What this repo is not (today)

- Not a framework. The word is aspirational until the [roadmap](../roadmap/) Wave 4+ ships. Today it's one person's working version of the pattern.
- Not a personal memory vault. Active state lives in a separate private repo.
- Not a transcript dump or raw research scrapbook.
- Not a hosted product, SaaS, or replacement for source systems.
- Not a one-time static document set; entries carry confidence and last-verified metadata and are revisable.

## Always private (never commit here)

- observations.jsonl
- active-threads.md
- active-memory-brief.md
- open-loops.md
- goals.md
- decision-journal.md
- status-update.md
- performance-map.md
- memory-scoreboard.md
- memory-top-patterns.md

## Quality bar for adding shared memory

!!! abstract "All four must pass — no exceptions"
    1. **Reusable** — works beyond one company, incident, or tool.
    2. **Measurable** — includes a KPI or verification signal.
    3. **Falsifiable** — includes a counter-opinion or failure mode.
    4. **Fresh** — includes confidence and last-verified date.

## Promotion and removal defaults

- Promote personal lessons only after repeated successful reuse.
- If a shared rule is not revalidated, downgrade confidence and eventually archive it.
- Prefer short, high-signal updates over long narrative history.

## Decision rule for contributors

!!! tip "One-line rule"
    If a proposed addition is specific to one person, one machine, or one short-lived event, keep it in a private/personal repo. If it is reusable and testable across contexts, it belongs here.