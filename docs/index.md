# my-agent-memory

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Stop your agent's memory from becoming 97% garbage.</h1>
			<p class="lead">mem0 has a <a href="https://github.com/mem0ai/mem0/issues/4573">documented 97.8% junk rate</a> in production. The official MCP Memory server stores everything with no filter. Claude Code's auto-memory relies on LLM judgment alone. Every memory system stores indiscriminately. This project builds the part that says <strong>no</strong>.</p>
			<div class="pill-row">
				<span class="pill">100/100/100 accuracy</span>
				<span class="pill">4-dimension scoring</span>
				<span class="pill">PowerShell & Python</span>
			</div>
			<div class="cta-row">
				<a class="md-button md-button--primary" href="try-it/">Try the scorer</a>
				<a class="md-button" href="evidence/">See the evidence</a>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>The problem</strong>
				<span>Every memory system stores indiscriminately. Result: noise drowns signal and agents get dumber over time, not smarter.</span>
			</div>
			<div class="kpi-item">
				<strong>The solution</strong>
				<span>A scoring layer that evaluates reusability, atomicity, novelty, and actionability. Below threshold = rejected with a reason.</span>
			</div>
			<div class="kpi-item">
				<strong>The proof</strong>
				<span>100% accuracy on a 100-item labeled fixture. 1.0% rejection on a 381-item real corpus. Zero false positives.</span>
			</div>
		</div>
	</div>
</div>

## Before / after

<div class="bento-grid">
	<div class="bento-card wide">
		<span class="meta">Rejected / garbage</span>
		<h3>"Session started 2026-05-26 at 09:00 on office-pc."</h3>
		<p>Score: <strong>-0.7</strong> &mdash; Timestamp + machine name = transient state. Never useful in a future session. This is what 97% of stored memories look like.</p>
	</div>
	<div class="bento-card wide">
		<span class="meta">Kept / valuable</span>
		<h3>"Avalonia DataGrid is a separate NuGet package; must dotnet add package Avalonia.Controls.DataGrid before using it."</h3>
		<p>Score: <strong>0.85</strong> &mdash; Specific gotcha, reusable across sessions, atomic, actionable. This is what memory should look like.</p>
	</div>
</div>

## What it does

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Filter</span>
		<h3>Scores every candidate on 4 dimensions</h3>
		<p>Reusability, atomicity, novelty, actionability. 40+ rules catch the junk categories that plague production memory systems.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Detect</span>
		<h3>Catches contradictions against existing store</h3>
		<p>Polarity + subject overlap analysis. Flags when a new memory conflicts with what's already stored instead of silently creating duplicates.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Prevent</span>
		<h3>Blocks feedback loops</h3>
		<p>Stops recalled memories from being re-extracted as "new" observations. Prevents the failure mode that created 668 copies of a single hallucination in mem0.</p>
	</div>
</div>

## The landscape

| Project | Stars | Quality Gate |
|---------|-------|-------------|
| mem0 | 56.8k | Hash dedup only — [97.8% junk documented](https://github.com/mem0ai/mem0/issues/4573) |
| MCP Memory (official) | — | None (9 tools, no filtering) |
| Claude Code auto-memory | — | LLM judgment only (200-line cap) |
| memory-bank-mcp | 905 | None (raw read/write) |
| Tensory | 4 | Salience scoring (alpha, tiny) |
| **This project** | — | **4-dimension scoring + contradiction + feedback-loop prevention** |

## How the scoring works

<div class="bento-grid">
	<div class="bento-card tall">
		<span class="meta">Dimension 1</span>
		<h3>Reusability</h3>
		<p>Would this help in a future session on a different project? Penalizes timestamps, machine names, file paths, sprint references.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Dimension 2</span>
		<h3>Atomicity</h3>
		<p>One discrete fact, not a compound paragraph? Multi-concern blobs get penalized.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Dimension 3</span>
		<h3>Novelty</h3>
		<p>Does the store already know this? Contradiction detection and feedback-loop prevention live here.</p>
	</div>
	<div class="bento-card tall">
		<span class="meta">Dimension 4</span>
		<h3>Actionability</h3>
		<p>Does it change behavior? Vague truisms, self-praise, and empty agreements score zero or negative.</p>
	</div>
</div>

## Try it in 60 seconds

```bash
git clone https://github.com/victorfelisbino/my-agent-memory.git
cd my-agent-memory/admission-gate
echo '{"text":"Always use try-catch in JavaScript"}' | python3 score_memory.py --score-one
```

```json
{"decision":"keep","total":1.1,"reusability":0.3,"atomicity":0.3,"novelty":0.0,"actionability":0.5}
```

Exit code 0 = keep. Exit code 3 = reject. Pipe into any pipeline.

<div class="cta-row">
	<a class="md-button md-button--primary" href="try-it/">Full quickstart guide</a>
	<a class="md-button" href="the-gate/">How the gate works</a>
</div>

## Honest scope

!!! note "What this is today"
    A working admission gate (PowerShell + Python) with 100% accuracy on its test set, integrated into a real daily-use memory system. It is **not** an MCP server yet — that's [Wave 5](roadmap/) on the roadmap. Today you use it by cloning the repo and running the scorer locally or embedding it in your pipeline. The [roadmap](roadmap/) shows what's next.

## Pages worth reading

<div class="bento-grid">
	<a class="bento-card tall" href="the-gate/">
		<span class="meta">Technical</span>
		<h3>How the gate works</h3>
		<p>The four dimensions, contradiction detection, feedback-loop prevention, and the full rule catalog.</p>
	</a>
	<a class="bento-card tall" href="evidence/">
		<span class="meta">Proof</span>
		<h3>Evidence</h3>
		<p>Fixture methodology, iteration history, real-corpus results, before/after examples, and honest limitations.</p>
	</a>
	<a class="bento-card tall" href="try-it/">
		<span class="meta">Action</span>
		<h3>Try it</h3>
		<p>Clone, run, score your own corpus. 60 seconds to first result, zero dependencies.</p>
	</a>
	<a class="bento-card tall" href="roadmap/">
		<span class="meta">Direction</span>
		<h3>Roadmap</h3>
		<p>Six waves from working scorer to MCP server. Each wave has a kill switch.</p>
	</a>
</div>
