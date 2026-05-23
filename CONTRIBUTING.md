# Contributing

Thanks for helping improve this framework.

## Scope

This repository is the shared framework only. Do not add personal memory state here.

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
4. Update README if command behavior changes.
5. Do not include secrets, local machine paths, or personal memory content.

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
