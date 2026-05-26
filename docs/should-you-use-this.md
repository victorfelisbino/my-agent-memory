# Is this for you?

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Probably yes if you already keep two kinds of notes.</h1>
			<p class="lead">This repo is the <em>shared</em> half of a two-repo pattern: keep private signal (observations, client names, active state) in a personal repo, promote only the generalized lessons here, and let every agent session pull from this side. Use it as-is, fork it, or steal the pattern &mdash; whichever fits.</p>
			<div class="pill-row">
				<span class="pill">Pair with a private repo</span>
				<span class="pill">Markdown + scripts</span>
				<span class="pill">Weekly cadence assumed</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Likely fit</strong>
				<span>You use a coding agent daily, work across multiple projects, and want lessons to compound instead of evaporating.</span>
			</div>
			<div class="kpi-item">
				<strong>Maybe</strong>
				<span>You like the idea but won't run a weekly review. The promotion loop is what makes the shared layer worth reading from.</span>
			</div>
			<div class="kpi-item">
				<strong>Probably not</strong>
				<span>You want a hosted product with a UI. Use <a href="https://github.com/mem0ai/mem0">mem0</a> or one of the other memory frameworks instead.</span>
			</div>
		</div>
	</div>
</div>

## Use this pattern if

- You use a coding agent (Copilot, Cursor, Cline, etc.) across more than one project and want lessons learned in one to help the next.
- You already keep private notes somewhere and want a clean way to graduate the durable ones into a shared layer your agent reads.
- You're comfortable with plain markdown and a couple of PowerShell or bash scripts &mdash; no SaaS, no DB, no MCP server required to start.
- You'll run a weekly review. The promotion gate is the whole point; without it the shared layer fills with noise.

## Skip it if

- You want a hosted product with a UI. There isn't one here.
- You won't separate private from shared. Without the split you may as well dump everything into one note app.
- You won't maintain a weekly cadence.
- You need enterprise governance, SSO, audit logs, etc. Not here.

## Realistic time cost

- **Daily**: under two minutes to capture an observation or run the restart routine, assuming fewer than ten active threads. More threads = longer.
- **Weekly**: 20-30 minutes to review observations, promote what's reusable, and prune what's stale. This is the part that matters and the first thing to slip.

## If you want to try it

1. Skim the [Quick restart routine](../quick-restart-routine/) to see the daily shape.
2. Read [What stays private](../framework-scope/) &mdash; this is the rule that keeps the two repos cleanly separated.
3. Look at [Memory adoption playbook](../memory-adoption-playbook/) for the promotion gate.
4. Either fork this repo as your shared layer, or just steal the parts of the pattern that fit.

!!! tip "What to take first if you're cherry-picking"
    The two pieces I haven't seen packaged elsewhere are the Copilot router-hints header (see [Copilot auto-mode](../copilot-auto-mode/)) and the anti-hallucination protocol auto-injected by <code>summon-memory</code>. Everything else &mdash; markdown KB, weekly review, decision journal &mdash; is well-trodden territory you can lift from anywhere.
