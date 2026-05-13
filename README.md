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

That's it! Your memory is now available in every project, on every machine.

## Simplest workflow

Daily (30 seconds):

```powershell
cd "$env:APPDATA\Code\User\memories"
git pull
```

After an incident (2 minutes):

1. Copy lesson-template.md.
2. Fill root cause and guardrail.
3. Move distilled guardrail to gotchas.md or salesforce-debugging.md.

Weekly (1 command):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\learn-memory.ps1
```

By default, this scans Copilot transcript history across all VS Code workspaces on this machine.

Optional: scan only one transcript directory:

```powershell
.\learn-memory.ps1 -TranscriptDir "<path-to-transcripts>"
```

Weekly (one-command full runner):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\run-weekly-memory.ps1
```

To auto-commit and push in one shot:

```powershell
.\run-weekly-memory.ps1 -Commit -Push
```

Then review:

- memory-scoreboard.md
- memory-top-patterns.md
- weekly-review-checklist.md

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
