# my-agent-memory

[![CI](https://img.shields.io/github/actions/workflow/status/victorfelisbino/my-agent-memory/ci.yml?branch=main)](https://github.com/victorfelisbino/my-agent-memory/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**The quality gate for AI agent memory.** Not another storage layer &mdash; the opinionated filter that prevents your agent's memory from becoming 97% garbage.

mem0 (56.8k stars) has a [documented 97.8% junk rate](https://github.com/mem0ai/mem0/issues/4573) in production. The official MCP Memory server stores everything with no filter. Claude Code's auto-memory relies on LLM judgment alone. Every memory system stores indiscriminately. This project builds the part that says **no**.

Today it's one person's working version of a two-repo memory pattern for AI coding agents (Copilot, Cline, Cursor, Claude Code). It is **not a framework yet** &mdash; that word is on the [roadmap](docs/roadmap.md), Wave 5 onward. The shared side holds curated rules, playbooks, quality-gate designs, and scripts; a separate **private** repo holds active state.

What this repo solves, in plain language:

1. **Stop storing garbage.** A memory admission gate that scores candidate memories on reusability, atomicity, novelty, and actionability &mdash; and rejects the ones that fail. (Building &mdash; Wave 3.)
2. **Advertise what this brain knows.** A competence map that publishes expertise depth with computed evidence &mdash; honest by construction, refuses to render unsubstantiated claims. (Building &mdash; Wave 2.5.)
3. **Stop relearning the same lesson.** When the same shape of bug or decision shows up twice, the principle gets distilled, promoted here, and stays for next time.
4. **Make your agent start warm.** Lessons, guardrails, and decisions already paid for bias every new session through a context brief.
5. **Stop hallucination feedback loops.** Prevent recalled memories from being re-extracted as "new" observations &mdash; the failure mode that created 668 copies of a single hallucination in mem0.

What to read first:

- [docs/roadmap.md](docs/roadmap.md) &mdash; where this is going and the kill switches for each wave.
- [docs/status.md](docs/status.md) &mdash; what's actually working today vs documented-only vs planned.
- [docs/framework-scope.md](docs/framework-scope.md) &mdash; what belongs in this repo and what doesn't.
- [docs/index.md](docs/index.md) &mdash; the published site entry.
- [CONTRIBUTING.md](CONTRIBUTING.md) &mdash; if you want to propose a change.

## Start Here

- Reality check first: [docs/status.md](docs/status.md) &mdash; what's real today vs documented-only vs planned.
- What this brain knows: [docs/competence-map.md](docs/competence-map.md) &mdash; depth, evidence, and last-touch per domain. Generated, not hand-typed.
- Where this is going: [docs/roadmap.md](docs/roadmap.md) &mdash; 6 waves, each with a kill switch.
- New user setup: [Quick Start (5 minutes)](#quick-start-5-minutes)
- Published docs entry: [docs/index.md](docs/index.md)
- Purpose, in one paragraph: [docs/framework-purpose.md](docs/framework-purpose.md)
- Quick restart routine: [docs/quick-restart-routine.md](docs/quick-restart-routine.md)
- Architecture: [Two-repo split](#two-repo-split)
- Scope and privacy boundary: [docs/framework-scope.md](docs/framework-scope.md)
- Collaboration process: [CONTRIBUTING.md](CONTRIBUTING.md)

## What Stays Private Always

This repository must never contain personal working-state files. They live in a separate, private `my-agent-memory-personal` repo:

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

The `.gitignore` here already protects these paths.

## What this repo is trying to do

- **Stop losing threads.** One file (`open-loops.md` in the personal repo) holds every project you have going, what state it's in, who you owe what, and when you last touched it. Bounded lists, capped sections.
- **Help Copilot start warmer than zero.** Run `summon-memory` before a complex task; it ranks the relevant principles, gotchas, and recent observations into a context brief you paste into the prompt. *Manual today &mdash; auto-injection is on the [roadmap](docs/roadmap.md), not shipped.*
- **Make weekly review measurable.** Decisions, observations, and outcomes get captured automatically; the weekly run synthesizes them so review is about the few patterns that actually matter, not vibes.
- **Keep capture cheaper than review.** Recording something is one shell command. Pruning is a fixed 20-30 minute slot per week. If either side grows past those constraints, the system has failed and needs trimming.

## Two-repo split

```
my-agent-memory  (this repo, shareable)               my-agent-memory-personal  (private, per user)
- scripts (loop, sync, summon, capture, learn,        - observations.jsonl
  synthesize, prune, repair, install)                 - active-threads.md
- principles & protocols                              - active-memory-brief.md
  (anti-hallucination, thinking, decision,            - open-loops.md
   cognitive-bias, exploration)                       - goals.md
- curated reference docs                              - decision-journal.md
  (gotchas, salesforce-debugging,                     - status-update.md
   project-commands)                                  - performance-map.md
- domains/  (Salesforce, MuleSoft, general            - memory-scoreboard.md
   playbooks)                                         - memory-top-patterns.md
- skills/  (one shipped: anti-hallucination;          - team-memory/inbox/  (reserved; unused)
   others are templates and a couple of
   domain examples)
- team-memory/  (reserved structure for a
   future multi-contributor flow; currently
   empty — see team-memory/README.md)
- README + playbooks
```

The scripts find the personal repo via this resolution order:

1. `$env:AGENT_MEMORY_PERSONAL` (or `$AGENT_MEMORY_PERSONAL` on bash) if set
2. Sibling directory of the framework repo named `my-agent-memory-personal`
3. The framework repo itself (legacy fallback, useful for first-time exploration before splitting)

See [_personal-root.ps1](_personal-root.ps1) / [_personal-root.sh](_personal-root.sh).

Long-form guidance and research live under [docs/](docs/).

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

### 1. Knowledge layer (lives here, shared) — *what I've curated*
Markdown files `summon-memory` ranks and pulls into a brief you paste into Copilot:

- [anti-hallucination-protocol.md](anti-hallucination-protocol.md), [thinking-principles.md](thinking-principles.md), [decision-framework.md](decision-framework.md), [cognitive-bias-checks.md](cognitive-bias-checks.md), [exploration-modes.md](exploration-modes.md) — how to reason.
- [gotchas.md](gotchas.md), [salesforce-debugging.md](salesforce-debugging.md), [project-commands.md](project-commands.md) — curated practices and commands.
- [domains/](domains/) — domain-specific playbooks.
- [team-memory/](team-memory/) — reserved structure for a future multi-contributor promotion flow. Today the folders are empty; no lesson has actually flowed through `approval-gates.md`.

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

## Skills and connectors layer (mostly templates today)

The `skills/` and `connectors/` directories scaffold a more structured execution layer. Today:

- [`skills/general/anti-hallucination/`](skills/general/anti-hallucination/) is the one fully-shipped skill (Wave 1 of the [roadmap](docs/roadmap.md)) with install paths and a 5-prompt before/after harness.
- [`skills/general/pr-review/`](skills/general/pr-review/), [`skills/salesforce/`](skills/salesforce/), [`skills/mulesoft/`](skills/mulesoft/) hold one example each. They're useful as references; they are not consumed by any agent integration in a one-command, reproducible way.
- [`connectors/`](connectors/) contains only a README and a template. No connector contracts have been written yet.

If you want a structured skill, copy `skills/templates/skill-template.md` and follow the shape of the anti-hallucination skill. Don't expect a runtime to pick it up automatically &mdash; that's a planned wave, not a current feature.

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
    v  summon-memory.ps1  (scans this repo for relevant knowledge)
$PERSONAL/active-memory-brief.md  -->  YOU paste it into the next Copilot prompt
(ranked knowledge from this repo +
 your recent observations +
 your active threads)
```

That last step is manual today &mdash; the brief is generated, but no integration injects it into Copilot automatically. The roadmap's Wave 4-A is where auto-injection ships, if it ships.

Cross-machine sync for the **personal repo** uses git union-merge: [.gitattributes](.gitattributes) in the personal repo marks `observations.jsonl merge=union` so parallel pushes from N machines never conflict.

## Setup on a new machine

```powershell
# 1. Clone this repo (shareable)
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

All commands above are Windows / PowerShell. `.sh` counterparts exist for `loop`, `sync-memory`, `capture-observation`, `learn-memory`, `summon-memory`, `synthesize-observations`, `auto-capture-observations`, `lint-memory`, and `run-weekly-memory`, but the PowerShell path is the daily-driven one. Missing `.sh` equivalents: `prune-observations`, `repair-mojibake`, `install-scheduled-task` (Windows-only; no `cron` or `launchd` installer ships). See [docs/status.md](docs/status.md) for the cross-platform parity gap.

**Bootstrap the personal repo first** if you haven't already:

1. Create an empty **private** GitHub repo (e.g. `my-agent-memory-personal`).
2. Make a sibling directory next to this one:
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
See [docs/copilot-auto-mode.md](docs/copilot-auto-mode.md) for the auto-mode + token-saving strategy.

**Automatic** (no action required): the scheduled task runs `sync-memory.ps1 -Commit -Push` daily — pulls activity from your other machines, captures from local Copilot transcripts with machine + workspace attribution, regenerates `active-threads.md`, and pushes the **personal** repo. This repo doesn't get auto-updated by the task; `git pull` here is manual.

**Weekly**: `.\run-weekly-memory.ps1 -Commit -Push` runs the learner, captures, synthesizes, lints `team-memory/`, and commits **both** repos (curated updates here + personal data there).

## Operating principles

- **Evidence over claim.** Never accept "done" without independent verification — see [anti-hallucination-protocol.md](anti-hallucination-protocol.md).
- **Caps over completeness.** Bounded lists force pruning; unbounded lists become wikis nobody reads.
- **One verb, one file.** If a workflow needs more than one command or one place to look, it will be skipped.
- **Capture costs nothing, review costs everything.** Auto-capture is cheap and lossless; attention is the scarce resource and goes only to bounded sections.
- **Personal first, shared second.** Lessons should earn their way out of the private repo by reuse and a transfer test. The `team-memory/approval-gates.md` flow is reserved for when there's more than one contributor; today promotion is a manual judgement call.
- **Private data stays private.** The personal repo is always a separate, private repo — never push it to a shared remote.

## Community

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Code of conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Security policy: [SECURITY.md](SECURITY.md)

## Research and evolution

- Ecosystem landscape: [docs/memory-ecosystem-research-2026-05-15.md](docs/memory-ecosystem-research-2026-05-15.md)
- Practical adoption protocol: [docs/memory-adoption-playbook.md](docs/memory-adoption-playbook.md)
- Lesson capture standard: [lesson-template.md](lesson-template.md) and [team-memory/templates/shared-lesson-template.md](team-memory/templates/shared-lesson-template.md)
- Skills templates and starter packs: [skills/README.md](skills/README.md)
- Connector contracts: [connectors/README.md](connectors/README.md)
- Workflow command and router templates: [skills/templates/workflow-command-template.md](skills/templates/workflow-command-template.md), [skills/templates/router-template.md](skills/templates/router-template.md)
- Salesforce command/router examples: [skills/salesforce/commands/deploy-incident-workflow.md](skills/salesforce/commands/deploy-incident-workflow.md), [skills/salesforce/router/salesforce-router.md](skills/salesforce/router/salesforce-router.md)

## Why this exists

Manual second-brains fail because they require discipline nobody actually has. The bet here is that one disciplined behavior — typing one shell command when something happens — is achievable, and everything downstream (cross-machine sync, scoring, weekly synthesis, brief generation) can be automated from that one input.

That's the bet, not a proven outcome. Whether it works for anyone besides me is what the [roadmap](docs/roadmap.md) waves 2-4 are designed to test. Status today: [docs/status.md](docs/status.md).
