# My Personal Agent Memory

This repository contains my persistent memory for GitHub Copilot across all machines and projects.

## What's here

- **salesforce-debugging.md** - Salesforce debugging patterns, governor limits, performance tips
- **salesforce-patterns.md** - Apex/LWC/Flow best practices and anti-patterns
- **project-commands.md** - Frequently used commands (SF CLI, git, npm, etc.)
- **gotchas.md** - Common pitfalls and how to avoid them
- **deployment-checklist.md** - Pre-deployment validation steps
- **tools-and-aliases.md** - Useful tools, aliases, and configurations
- **anti-hallucination-protocol.md** - Evidence-first guardrails to reduce wrong assumptions
- **goals.md** - 30/90-day outcomes and weekly priorities
- **performance-map.md** - Where you perform best and what to avoid
- **decision-journal.md** - High-value decisions, outcomes, and lessons
- **thinking-principles.md** - Your default way of reasoning under uncertainty
- **decision-framework.md** - Consistent decision scoring and tradeoff method
- **cognitive-bias-checks.md** - Debiasing prompts to reduce bad judgments
- **exploration-modes.md** - Intentional problem-solving modes (triage, diagnosis, strategy)

## How it works

1. This folder is symlinked to your GitHub repo
2. Every VS Code workspace automatically loads these files into Copilot context
3. Add notes whenever you learn something useful
4. Commit and push to GitHub to sync across machines

## Getting started

Edit any `.md` file, then:

```bash
cd "$env:APPDATA\Code\User\memories"
git add .
git commit -m "Add new tip"
git push
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
git add .
git commit -m "Add new tip"
git push
```

That's it! Your memory is now available in every project, on every machine.

## Simplest workflow

Daily (30 seconds):

```powershell
cd "$env:APPDATA\Code\User\memories"
git pull
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
git pull
```

Daily across all 4 machines (one command per machine):

```powershell
.\sync-memory.ps1 -Commit -Push    # pulls, captures local Copilot activity tagged with machine + workspace, regenerates active-threads.md, pushes
```

macOS/Linux equivalent:

```bash
./sync-memory.sh --commit --push
```

Then open `active-threads.md` on any machine to see every project you have going, grouped by workspace, sorted by most recent activity, with machine attribution. Merge-safe: `.gitattributes` configures `observations.jsonl` for union merge so parallel pushes from different machines never conflict.

After an incident (2 minutes):

1. Copy lesson-template.md.
2. Fill root cause and guardrail.
3. Move distilled guardrail to gotchas.md or salesforce-debugging.md.

Weekly (1 command):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\learn-memory.ps1
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./learn-memory.sh
```

By default, this scans Copilot transcript history across all VS Code workspaces on this machine.

Optional: scan only one transcript directory:

```powershell
.\learn-memory.ps1 -TranscriptDir "<path-to-transcripts>"
```

macOS/Linux equivalent:

```bash
./learn-memory.sh --transcript-dir "<path-to-transcripts>"
```

Weekly (one-command full runner):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\run-weekly-memory.ps1
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./run-weekly-memory.sh
```

To auto-commit and push in one shot:

```powershell
.\run-weekly-memory.ps1 -Commit -Push
```

macOS/Linux equivalent:

```bash
./run-weekly-memory.sh --commit --push
```

Then review:

- memory-scoreboard.md
- memory-top-patterns.md
- weekly-review-checklist.md

Run team memory lint:

```powershell
.\lint-memory.ps1 -IncludeCanonical
```

macOS/Linux equivalent:

```bash
./lint-memory.sh --include-canonical
```

## Magic mode (task-specific memory recall)

Generate a focused brief before a complex task:

```powershell
cd "$env:APPDATA\Code\User\memories"
.\summon-memory.ps1 -Task "Build a .NET app that uses Salesforce OAuth and retrieves Accounts"
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./summon-memory.sh --task "Build a .NET app that uses Salesforce OAuth and retrieves Accounts"
```

This creates `active-memory-brief.md` with ranked snippets from:

- root memory files
- domains/general
- selected domain folder

It now includes:

- Auto domain routing from task keywords (`Auto` is default)
- Freshness weighting so newer lessons rank higher
- Optional preflight prompt output for copy/paste into chat

Print a ready-to-paste preflight prompt:

```powershell
.\summon-memory.ps1 -Task "Create Salesforce API integration with OAuth refresh tokens" -Preflight
```

macOS/Linux equivalent:

```bash
./summon-memory.sh --task "Create Salesforce API integration with OAuth refresh tokens" --preflight
```

Paste that brief into your next Copilot prompt to bias retrieval toward your proven patterns.

## Ecosystem research

Recent market scan and examples:

- `memory-ecosystem-research-2026-05-15.md`
- `memory-adoption-playbook.md`

## Team memory layer

Shared team memory with promotion gates lives in:

- `team-memory/README.md`
- `team-memory/approval-gates.md`
- `team-memory/templates/shared-lesson-template.md`

## Multi-domain use (Salesforce, MuleSoft, others)

- Shared rules: `domains/general/`
- Salesforce specifics: `domains/salesforce/`
- MuleSoft specifics: `domains/mulesoft/`

At task start, declare the domain in plain words:

- "Domain: Salesforce"
- "Domain: MuleSoft"
- "Domain: General"

This keeps recommendations relevant when switching projects.

## Learning loop (use after every incident)

1. What failed: one sentence only.
2. Root cause: branch process, metadata mismatch, permissions, or code defect.
3. Detection: how we could have caught it earlier.
4. Guardrail: command/checklist/test to prevent recurrence.
5. Evidence: link to deploy id, PR, or commit hash.

When adding a lesson, prefix with one of these tags:
- [P0 Prevented outage]
- [P1 Frequent failure]
- [P2 Nice to have]

Keep only lessons that are reusable in future work. Skip one-off context.

## Best-self mode

Use these files together:

1. goals.md: pick what matters most this week.
2. performance-map.md: choose work styles where you perform best.
3. anti-hallucination-protocol.md: enforce evidence-first answers.
4. decision-journal.md: capture strategic decisions and outcomes.

This helps with both execution quality and personal growth over time.

For important tasks, explicitly apply:

1. thinking-principles.md before planning
2. decision-framework.md before committing to an approach
3. cognitive-bias-checks.md before final decision
