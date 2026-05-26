# Is this for you?

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Probably not, and that's fine.</h1>
			<p class="lead">This is a personal toolkit, not a product. Copy the parts that fit your day. If none of the signals below feel like you, walk away &mdash; there are slicker memory tools out there.</p>
			<div class="pill-row">
				<span class="pill">No install required</span>
				<span class="pill">Markdown + scripts</span>
				<span class="pill">Weekly cadence assumed</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>Likely fit</strong>
				<span>You use Copilot daily, hit the same gotchas more than once, and already keep notes somewhere.</span>
			</div>
			<div class="kpi-item">
				<strong>Maybe</strong>
				<span>You like the idea but won't commit to a weekly 20-30 minute review. It will rot without one.</span>
			</div>
			<div class="kpi-item">
				<strong>Probably not</strong>
				<span>You want a polished app, a team product, or zero discipline overhead. Use <a href="https://github.com/mem0ai/mem0">mem0</a> or similar.</span>
			</div>
		</div>
	</div>
</div>

## Copy something from here if

- You use a coding agent (Copilot, Cursor, Cline, etc.) daily and notice it relearning the same things every session.
- You already fix the same classes of problems repeatedly and want them captured as guardrails the agent actually reads.
- You're comfortable with plain markdown and a couple of PowerShell or bash scripts &mdash; no SaaS, no DB, no MCP server required to start.
- You're willing to run a weekly review. The system rots fast without one.

## Skip it if

- You want a hosted product with a UI. There isn't one here.
- You won't maintain a weekly cadence. The whole promotion/retirement loop depends on it.
- You're after a turnkey team memory tool. This wasn't built for that and pretending otherwise would be dishonest.
- You need enterprise governance, SSO, audit logs, etc. Not here.

## Realistic time cost

- **Daily**: under two minutes to capture an observation or run the restart routine, assuming fewer than ten active threads. More threads = longer.
- **Weekly**: 20-30 minutes to review observations, promote what's reusable, and prune what's stale. This is the part that matters and the first thing to slip.

## If you want to try it

1. Skim the [Quick restart routine](../quick-restart-routine/) to see the daily shape.
2. Read [What stays private](../framework-scope/) before copying anything &mdash; the public/private split matters.
3. Look at [Memory adoption playbook](../memory-adoption-playbook/) for the promotion rules.
4. Steal whatever fits. Drop whatever doesn't.

!!! tip "What to take first if you're cherry-picking"
    The Copilot router-hints header (see [Copilot auto-mode](../copilot-auto-mode/)) and the anti-hallucination protocol are the two pieces I haven't seen packaged elsewhere. Everything else is well-trodden territory.
