# Quick Restart Routine

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Re-enter work with current context in minutes.</h1>
			<p class="lead">This routine restores focus after interruptions, selects one high-impact action, and logs state so execution stays continuous.</p>
			<div class="pill-row">
				<span class="pill">2-minute reset</span>
				<span class="pill">One next action</span>
				<span class="pill">Low token overhead</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>When to run</strong>
				<span>At context switches, interruptions, or start of a work block.</span>
			</div>
			<div class="kpi-item">
				<strong>Expected result</strong>
				<span>A single explicit next action logged in-system.</span>
			</div>
			<div class="kpi-item">
				<strong>Guardrail</strong>
				<span>If next action is unclear, narrow scope and rerun memory summon.</span>
			</div>
		</div>
	</div>
</div>

<div class="scan-grid">
	<div class="scan-card">
		<span class="meta">Step 1</span>
		<h3>Re-anchor active work</h3>
		<p>Review open loops and choose one highest-impact action.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Step 2</span>
		<h3>Refresh repo state</h3>
		<p>Sync memory and confirm active threads are current.</p>
	</div>
	<div class="scan-card">
		<span class="meta">Step 3-4</span>
		<h3>Load + log</h3>
		<p>Summon context, then capture the new state change immediately.</p>
	</div>
</div>

## Purpose

- Rebuild task context quickly.
- Resume execution with a single clear next action.

## When to use

- After interruptions or context switches.
- At the start of a work block.
- When next action is unclear.

## Inputs

- Personal open loops.
- Current repository state.
- Current task description.

## Steps

### Step 1: Re-anchor active work

1. Open personal open loops.
2. Review In-Flight, Promises, and Waiting On.
3. Select the highest-impact next action.

### Step 2: Refresh repository state

1. Run memory sync.
2. Confirm active threads are current.

### Step 3: Load task context

1. Run summon-memory for the active task.
2. Use compact mode when speed and low token usage are preferred.

### Step 4: Log next state change

1. `start` when work begins.
2. `wait` when blocked.
3. `promise` when a commitment is made.

## Command quick list

```powershell
.\sync-memory.ps1
.\loop.ps1 show
.\summon-memory.ps1 -Task "<current task>" -Compact -Preflight
.\loop.ps1 start "<task>"
```

## Guardrail

!!! warning "Stop and narrow"
    If the next action is unclear, narrow the task and rerun summon-memory before execution. Do not start work on an ambiguous prompt.

## Output

- One explicit next action logged in the system.