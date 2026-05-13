# My Personal Agent Memory

This repository contains my persistent memory for GitHub Copilot across all machines and projects.

## What's here

- **salesforce-debugging.md** - Salesforce debugging patterns, governor limits, performance tips
- **salesforce-patterns.md** - Apex/LWC/Flow best practices and anti-patterns
- **project-commands.md** - Frequently used commands (SF CLI, git, npm, etc.)
- **gotchas.md** - Common pitfalls and how to avoid them
- **deployment-checklist.md** - Pre-deployment validation steps
- **tools-and-aliases.md** - Useful tools, aliases, and configurations

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

Then review:

- memory-scoreboard.md
- memory-top-patterns.md
- weekly-review-checklist.md

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
