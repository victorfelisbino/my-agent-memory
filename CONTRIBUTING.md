# Contributing

Thanks for looking. Before opening anything, read [docs/status.md](docs/status.md) and [docs/roadmap.md](docs/roadmap.md) &mdash; this repo is one person's working version of a two-repo memory pattern, not a framework with users yet. Contribution shape that's actually useful depends on which roadmap wave we're in.

## Reality check

- Single contributor today. No published release cadence. CI runs only syntax-level checks (`bash -n`, PowerShell parse), not functional tests.
- The `team-memory/` approval-gates flow has never run end-to-end. Don't treat it as a working review process; treat it as a draft policy.
- The most useful contributions right now are: (a) running the [anti-hallucination test harness](skills/general/anti-hallucination/test-prompts.md) and reporting honest results, (b) flagging where the docs still claim something that isn't true.

## Scope

This repository holds shared, reusable patterns only. Personal memory state belongs in a separate, private `my-agent-memory-personal` repo.

Never commit these personal files:

- observations.jsonl
- active-threads.md
- active-memory-brief.md
- open-loops.md
- goals.md
- decision-journal.md
- status-update.md
- performance-map.md
- memory-scoreboard.md
- memory-top-patterns.md

## Development setup

1. Fork this repository.
2. Clone your fork.
3. Run scripts from the repo root.
4. Use a separate private personal repository for your own data.

## Pull request guidelines

1. Keep changes small and focused.
2. Explain the user problem and why the change is needed.
3. Include before-after behavior or sample output when changing scripts.
4. Update README and [docs/status.md](docs/status.md) if a behavior moves between "documented only" and "real today."
5. Do not include secrets, local machine paths, or personal memory content.
6. If you're changing a public claim about what works, link to evidence in the PR description.

## Validation

Before opening a PR, run:

```powershell
pwsh -NoProfile -File .\lint-memory.ps1
```

If your environment does not have pwsh, run at minimum:

```powershell
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; Get-ChildItem -File *.ps1 | ForEach-Object { [void][System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$null) }; Write-Host 'PowerShell parse OK'"
```

```bash
for f in ./*.sh; do bash -n "$f"; done
```

## Reporting issues

Use GitHub Issues with reproducible steps and expected behavior.

## Code of conduct

By participating, you agree to follow the Code of Conduct in CODE_OF_CONDUCT.md.
