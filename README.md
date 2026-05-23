# my-agent-memory (framework)

[![Release](https://img.shields.io/github/v/release/victorfelisbino/my-agent-memory)](https://github.com/victorfelisbino/my-agent-memory/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/victorfelisbino/my-agent-memory/ci.yml?branch=main)](https://github.com/victorfelisbino/my-agent-memory/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A git-backed memory system that solves two related problems at once:

1. **For humans**: when you run too many projects across too many machines, you forget what you've started, what you've promised people, and what you've actually shipped. This gives you one source of truth you can trust more than your memory.
2. **For GitHub Copilot**: every Copilot session starts cold. Decisions you've already made, guardrails you've already learned, and work you have in flight on another machine should bias every new answer. This makes that automatic.

This is the **framework repo** — scripts, playbooks, principles, and shared knowledge. It contains no personal data. Each user pairs it with a **separate, private personal repo** that holds their own observations, open loops, decisions, and active threads. The two repos are intentionally split so this one can be shared with collaborators without leaking anyone's working state.

## Start Here

- New user setup: [Quick Start (5 minutes)](#quick-start-5-minutes)
- Architecture: [Two-repo architecture](#two-repo-architecture)
- Privacy boundary: [What Stays Private Always](#what-stays-private-always)
- Collaboration process: [CONTRIBUTING.md](CONTRIBUTING.md)

## What Stays Private Always

This repository must never contain personal working-state files. Each collaborator keeps these in their own private personal repo:

- `observations.jsonl`
- `active-threads.md`
- `active-memory-brief.md`
- `open-loops.md`
- `goals.md`
- `decision-journal.md`
- `status-update.md`
- `performance-map.md`
- `memory-scoreboard.md`
- `memory-top-patterns.md`

The framework `.gitignore` already protects these paths, but privacy is also a contributor rule.

## What we're trying to accomplish

- **Never lose a thread.** Across N machines and M workspaces, you should be able to open one file and see every project you have going, what state it's in, who you owe what, and when you last touched it.
- **Make every Copilot session start smart.** Patterns, guardrails, decisions, and lessons already paid for should automatically bias new Copilot answers.
- **Verifiable progress over time.** Decisions, observations, and outcomes captured automatically and scored, so weekly review surfaces the few patterns that actually matter — not vibes.
- **Zero-friction capture, hard-bounded review.** If recording something takes more than one shell command, it won't happen. If lists can sprawl, they will. So: capture is one verb, review is a 60-second daily ritual, lists have caps.

## Two-repo architecture

```
my-agent-memory  (this repo, shareable)               my-agent-memory-personal  (private, per user)
- scripts (loop, sync, summon, capture, learn,        - observations.jsonl
  synthesize, prune, repair, install)                 - active-threads.md
- principles & protocols                              - active-memory-brief.md
  (anti-hallucination, thinking, decision,            - open-loops.md
   cognitive-bias, exploration)                       - goals.md
- verified-knowledge docs                             - decision-journal.md
  (gotchas, salesforce-debugging,                     - status-update.md
   project-commands)                                  - performance-map.md
- domains/  (Salesforce, MuleSoft, general            - memory-scoreboard.md
   playbooks)                                         - memory-top-patterns.md
- team-memory/  (canonical lessons,                   - team-memory/inbox/  (your pending lessons)
   templates, approval gates)
- README + playbooks
```

The framework scripts find the personal repo via this resolution order:

1. `$env:AGENT_MEMORY_PERSONAL` (or `$AGENT_MEMORY_PERSONAL` on bash) if set
2. Sibling directory of the framework repo named `my-agent-memory-personal`
3. The framework repo itself (legacy fallback, useful for first-time exploration before splitting)

See [_personal-root.ps1](_personal-root.ps1) / [_personal-root.sh](_personal-root.sh).

## Quick Start (5 minutes)

```powershell
# Clone framework
git clone https://github.com/victorfelisbino/my-agent-memory.git E:\my-agent-memory

# Clone your private personal repo as a sibling directory
git clone https://github.com/<you-or-your-org>/my-agent-memory-personal.git E:\my-agent-memory-personal

# Set personal-repo path once
[Environment]::SetEnvironmentVariable('AGENT_MEMORY_PERSONAL', 'E:\my-agent-memory-personal', 'User')

# Smoke test
cd E:\my-agent-memory
.\sync-memory.ps1
.\loop.ps1 show
```

If you are creating your personal repo for the first time, use the full setup in [Bootstrapping a personal repo](#bootstrapping-a-personal-repo-first-machine-only).

## The three layers

### 1. Knowledge layer (lives here, shared) — *what we've learned*
Curated markdown files Copilot pulls into context to bias its answers:

- [anti-hallucination-protocol.md](anti-hallucination-protocol.md), [thinking-principles.md](thinking-principles.md), [decision-framework.md](decision-framework.md), [cognitive-bias-checks.md](cognitive-bias-checks.md), [exploration-modes.md](exploration-modes.md) — how to reason.
- [gotchas.md](gotchas.md), [salesforce-debugging.md](salesforce-debugging.md), [project-commands.md](project-commands.md) — verified, evidence-backed practices.
- [domains/](domains/) — domain-specific playbooks.
- [team-memory/](team-memory/) — lessons promoted from personal use into shared practice through [approval gates](team-memory/approval-gates.md).

### 2. Activity layer (lives in the personal repo) — *what you've been doing*
Auto-captured from your local Copilot transcripts on every machine:

- `observations.jsonl` — append-only signals (decisions, blockers, progress, insights, dead-ends), tagged with `machine:` and `workspace:`. Secrets are scrubbed at capture time by [auto-capture-observations.ps1](auto-capture-observations.ps1).
- `active-threads.md` — auto-generated cross-machine view of every project you're touching.
- `status-update.md`, `memory-scoreboard.md`, `memory-top-patterns.md` — weekly synthesis.

### 3. Tracking layer (lives in the personal repo) — *what's actually open*
Manual but one-command, with hard caps:

- `open-loops.md` — single source of truth (Active Ideas cap 7, In-Flight cap 5, Promises, Waiting On, Done this week).
- [loop.ps1](loop.ps1) / [loop.sh](loop.sh) — one command, six verbs: `idea`, `start`, `promise`, `wait`, `done`, `show`. Every capture also writes to `observations.jsonl`.
- `goals.md`, `decision-journal.md`, `performance-map.md` — longer-arc tracking.

## How the layers connect

```
Copilot transcripts (per workspace, per machine)
    |
    v  auto-capture-observations.ps1  (UTF-8, secrets scrubbed)
    |
$PERSONAL/observations.jsonl  <----  loop.ps1  <----  you (1 command)
    |                                     |
    v                                     v
$PERSONAL/active-threads.md         $PERSONAL/open-loops.md
(what you're doing,                 (what's open,
 across all your machines)           bounded + reviewed)
    |
    v  summon-memory.ps1  (scans this framework repo for relevant knowledge)
$PERSONAL/active-memory-brief.md  -->  paste into next Copilot prompt
(ranked knowledge from framework +
 your recent observations +
 your active threads)
```

Cross-machine sync for the **personal repo** uses git union-merge: [.gitattributes](.gitattributes) in the personal repo marks `observations.jsonl merge=union` so parallel pushes from N machines never conflict.

## Setup on a new machine

```powershell
# 1. Clone this framework repo (shareable)
git clone https://github.com/victorfelisbino/my-agent-memory.git E:\my-agent-memory

# 2. Clone (or init) your private personal repo as a SIBLING directory
git clone https://github.com/<you-or-your-org>/my-agent-memory-personal.git E:\my-agent-memory-personal
# (or, on your first machine, see "Bootstrapping a personal repo" below)

# 3. (Optional but recommended) pin the personal-repo path explicitly
[Environment]::SetEnvironmentVariable('AGENT_MEMORY_PERSONAL', 'E:\my-agent-memory-personal', 'User')

# 4. Smoke-test
cd E:\my-agent-memory
.\sync-memory.ps1                          # pulls personal repo, captures, regenerates active-threads.md
.\loop.ps1 show                            # prints your open loops

# 5. Install the daily auto-sync task (runs sync-memory.ps1 -Commit -Push every morning)
.\install-scheduled-task.ps1 -DailySync -Time '08:00'
```

### Bootstrapping a personal repo (first machine only)

1. Create an empty **private** GitHub repo (e.g. `my-agent-memory-personal`).
2. Make a sibling directory next to the framework repo:
   ```powershell
   New-Item -ItemType Directory E:\my-agent-memory-personal
   cd E:\my-agent-memory-personal
   git init -b main
   # Optional but recommended — enables conflict-free parallel pushes:
   'observations.jsonl merge=union' | Set-Content .gitattributes
   git remote add origin <your-private-repo-url>
   ```
3. Run `..\my-agent-memory\sync-memory.ps1` once — it will create `observations.jsonl`, `active-threads.md`, etc.
4. Commit and push to your private repo:
   ```powershell
   git add -A; git commit -m "init: personal memory store"; git push -u origin main
   ```

## Daily operating rhythm

**Morning (60 seconds), every machine**: open `$PERSONAL\open-loops.md` and run the ritual at the top.

**Capture as you go (1 command)**:
```powershell
.\loop.ps1 idea    "thing I want to do"
.\loop.ps1 start   "thing I just began"
.\loop.ps1 promise "thing I told someone" -To Name -By 2026-05-30
.\loop.ps1 wait    "thing I'm blocked on" -On Person
.\loop.ps1 done    "thing I finished"
```

**Before a complex Copilot task** (optional):
```powershell
.\summon-memory.ps1 -Task "describe the task in plain words" -Preflight
# For a denser, cheaper brief that plays well with Copilot's auto-mode (10% discount):
.\summon-memory.ps1 -Task "describe the task" -Compact -Preflight
```
See [copilot-auto-mode.md](copilot-auto-mode.md) for the auto-mode + token-saving strategy.

**Automatic** (no action required): the scheduled task runs `sync-memory.ps1 -Commit -Push` daily — pulls everyone else's activity (from your other machines), captures from local Copilot transcripts with machine + workspace attribution, regenerates `active-threads.md`, and pushes. Only the personal repo gets pushed by this task; framework updates are a separate, manual `git pull` here.

**Weekly**: `.\run-weekly-memory.ps1 -Commit -Push` runs the learner, captures, synthesizes, lints team memory, and commits **both** repos (framework knowledge updates + personal data).

## Operating principles

- **Evidence over claim.** Never accept "done" without independent verification — see [anti-hallucination-protocol.md](anti-hallucination-protocol.md).
- **Caps over completeness.** Bounded lists force pruning; unbounded lists become wikis nobody reads.
- **One verb, one file.** If a workflow needs more than one command or one place to look, it will be skipped.
- **Capture costs nothing, review costs everything.** Auto-capture is cheap and lossless; human attention is the scarce resource and goes only to bounded sections.
- **Personal first, team second.** Lessons earn their way into shared framework knowledge through [team-memory/approval-gates.md](team-memory/approval-gates.md), not by default.
- **Private data stays private.** The personal repo is always a separate, private repo — never push it to a shared remote.

## Community

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Code of conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Security policy: [SECURITY.md](SECURITY.md)

## Why this exists

Manual second-brains fail because they require discipline nobody actually has. This system requires one disciplined behavior: type one shell command when something happens. Everything downstream — cross-machine sync, scoring, weekly synthesis, Copilot context injection — happens automatically from that one input.

If it works, you stop dropping threads, you stop relearning the same lessons, and Copilot gets measurably more useful every week. If it stops working, the failure shows up in the daily ritual within 24 hours, not weeks later.
