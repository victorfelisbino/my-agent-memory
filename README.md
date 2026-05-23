# My Personal Agent Memory

A git-backed memory system that solves two related problems at once:

1. **For me as a human**: I run too many projects across 4 machines, forget what I've started, what I've promised people, and what I've actually shipped. I needed one source of truth I can trust more than my own memory.
2. **For GitHub Copilot**: every Copilot session starts cold — no awareness of decisions I've already made, guardrails I've already learned, or work I have in flight on another machine. I needed Copilot to walk into each task with my full operating context.

This repo is the answer to both. It's not a knowledge base. It's an **operating system for my own work** that also doubles as Copilot's long-term memory.

## What we're trying to accomplish

**Goal 1 — Never lose a thread.** Across 4 machines and a dozen workspaces, I should be able to open one file and see every project I have going, what state it's in, who I owe what, and when I last touched it. No mental load required.

**Goal 2 — Make every Copilot session start smart.** Patterns, guardrails, decisions, and lessons I've already paid for should automatically bias new Copilot answers. Repeated failure modes (deploy churn, PR confusion, permission mismatches, hallucinated component names) should be caught by enforced checks, not relearned every time.

**Goal 3 — Verifiable progress over time.** Decisions, observations, and outcomes are captured automatically and scored, so weekly review surfaces the few patterns that actually matter — not vibes.

**Goal 4 — Zero-friction capture, hard-bounded review.** If recording something takes more than one shell command, it won't happen. If the system can sprawl into a wiki, it will, and become useless. So: capture is one verb, review is a 60-second daily ritual, and lists have caps that force pruning.

## How the system is built

Three layers, all in this repo:

### 1. Knowledge layer — *what I've learned*
Curated markdown files Copilot pulls into context to bias its answers:

- [anti-hallucination-protocol.md](anti-hallucination-protocol.md), [thinking-principles.md](thinking-principles.md), [decision-framework.md](decision-framework.md), [cognitive-bias-checks.md](cognitive-bias-checks.md), [exploration-modes.md](exploration-modes.md) — how I want Copilot (and myself) to reason.
- [gotchas.md](gotchas.md), [salesforce-debugging.md](salesforce-debugging.md), [project-commands.md](project-commands.md) — verified, evidence-backed practices.
- [domains/](domains/) — domain-specific playbooks (Salesforce, MuleSoft, general).
- [team-memory/](team-memory/) — lessons promoted from personal use into shared team practice through approval gates.

### 2. Activity layer — *what I've been doing*
Auto-captured from Copilot transcripts on every machine:

- [observations.jsonl](observations.jsonl) — append-only log of decisions, blockers, progress, insights, dead-ends. Each entry is tagged with `machine:HOSTNAME` and `workspace:NAME` so the source of every signal is traceable.
- [active-threads.md](active-threads.md) — auto-generated cross-machine view: every active project, grouped by workspace, sorted by recency, showing which machine touched it last. **This is the answer to "what am I working on?"**
- [status-update.md](status-update.md), [memory-scoreboard.md](memory-scoreboard.md), [memory-top-patterns.md](memory-top-patterns.md) — weekly synthesis surfacing recurring failure patterns and recent decisions.

### 3. Tracking layer — *what's actually open*
Manual but ultra-low-friction, with hard caps to prevent sprawl:

- [open-loops.md](open-loops.md) — the single source of truth: Active Ideas (cap 7), In-Flight (cap 5), Promises, Waiting On, Done this week. If it's not here, it doesn't exist.
- [loop.ps1](loop.ps1) / [loop.sh](loop.sh) — one command, six verbs: `idea`, `start`, `promise`, `wait`, `done`, `show`. Every capture also writes to `observations.jsonl` so nothing escapes the audit trail.
- [goals.md](goals.md), [decision-journal.md](decision-journal.md), [performance-map.md](performance-map.md) — longer-arc tracking (30/90-day outcomes, strategic decisions, where I perform best).

## How the layers work together

```
Copilot transcripts (per workspace, per machine)
    |
    v  auto-capture-observations.ps1  (UTF-8, secrets scrubbed)
    |
observations.jsonl  <----------  loop.ps1  <----  me (1 command)
    |                                |
    v                                v
active-threads.md               open-loops.md
(what I'm doing,                (what's open,
 across machines)                bounded + reviewed)
    |
    v  summon-memory.ps1
active-memory-brief.md  -->  paste into next Copilot prompt
(ranked knowledge +
 recent observations +
 active threads)
```

Cross-machine sync is git-backed. [.gitattributes](.gitattributes) configures `observations.jsonl` as `merge=union` so parallel pushes from 4 machines never conflict — each machine just adds its lines.

## Daily operating rhythm

**Morning (60 seconds), every machine**: open [open-loops.md](open-loops.md) and run the 4-step ritual at the top.

**Capture as you go (1 command)**:
```powershell
.\loop.ps1 idea    "thing I want to do"
.\loop.ps1 start   "thing I just began"
.\loop.ps1 promise "thing I told someone" -To Name -By 2026-05-30
.\loop.ps1 wait    "thing I'm blocked on" -On Person
.\loop.ps1 done    "thing I finished"
```

**Automatic sync (no action required)**: a scheduled task on each machine runs `sync-memory.ps1 -Commit -Push` daily at 08:00. It pulls everyone else's activity, captures fresh observations from local Copilot transcripts with machine + workspace attribution, regenerates `active-threads.md`, and pushes.

**Before a complex task** (optional but recommended):
```powershell
.\summon-memory.ps1 -Task "describe the task in plain words" -Preflight
```
Generates a ranked brief of relevant lessons + recent observations + active threads, and prints a ready-to-paste preflight prompt for Copilot.

**Weekly (one command)**: `.\run-weekly-memory.ps1 -Commit -Push` — runs the learner, captures, synthesizes, lints team memory, stages, commits, pushes.

## Setup on a new machine

1. Clone this repo to wherever your VS Code user folder lives (default symlink target: `$env:APPDATA\Code\User\memories` on Windows, `$HOME/Library/Application Support/Code/User/memories` on macOS/Linux).
2. Run once to verify capture works locally:
   ```powershell
   .\sync-memory.ps1
   ```
3. Install the daily auto-sync task:
   ```powershell
   .\install-scheduled-task.ps1 -DailySync -Time '08:00'
   ```
4. Done. The machine is now part of the shared brain.

## Operating principles

- **Evidence over claim.** Never accept "done" without independent verification — see [anti-hallucination-protocol.md](anti-hallucination-protocol.md).
- **Caps over completeness.** Bounded lists force pruning; unbounded lists become wikis nobody reads.
- **One verb, one file.** If a workflow needs more than one command or one place to look, it will be skipped.
- **Capture costs nothing, review costs everything.** Auto-capture is cheap and lossless; human attention is the scarce resource and goes only to bounded sections.
- **Personal first, team second.** Lessons earn their way into shared memory through approval gates in [team-memory/](team-memory/), not by default.

## Why this exists

I don't have the discipline to maintain a manual second-brain. I do have the discipline to type one command. This system is built around that constraint: the friction floor for capture is one shell command, and everything downstream — cross-machine sync, scoring, weekly synthesis, Copilot context injection — happens automatically from that one input.

If it works, I stop dropping threads, I stop relearning the same lessons, and Copilot gets measurably more useful every week. If it stops working, the failure shows up in the daily ritual within 24 hours, not weeks later.
