# My Commands & Shortcuts

## Salesforce SF CLI

### Deploy

Single file:
```powershell
sf project deploy start -d unpackaged/main/default/classes/MyClass.cls --target-org loves-omni --wait 10 --ignore-conflicts 2>&1 | cat
```

Multiple files:
```powershell
sf project deploy start -d unpackaged/main/default/classes/ -d unpackaged/main/default/lwc/myComponent --target-org loves-omni --wait 10 --ignore-conflicts 2>&1 | cat
```

By metadata:
```powershell
sf project deploy start --metadata "ApexClass:MyClass,LightningComponentBundle:myComponent" --target-org loves-omni --wait 10 --ignore-conflicts 2>&1 | cat
```

### Retrieve

```powershell
sf project retrieve start --metadata "ApexClass:MyClass" --target-org loves-omni --wait 10
```

### Environment Variables (Fixes EEXIT:130 hang)

```powershell
$env:SF_DISABLE_SOURCE_MEMBER_POLLING = "true"
$env:SFDX_DISABLE_SOURCE_MEMBER_POLLING = "true"
```

Or permanently set:
```powershell
[System.Environment]::SetEnvironmentVariable("SF_DISABLE_SOURCE_MEMBER_POLLING", "true", "User")
```

## Git 

Sync your memory from GitHub:
```bash
cd "$env:APPDATA\Code\User\memories"
git pull
git add .
git commit -m "Add new tip"
git push
```

macOS/Linux equivalent:
```bash
cd "$HOME/Library/Application Support/Code/User/memories"
git pull
git add .
git commit -m "Add new tip"
git push
```

Branch verification before PR/deploy:
```bash
# Compare current branch against qa
git fetch origin
git rev-list --left-right --count origin/qa...HEAD

# See exact commits not in qa yet
git log --oneline origin/qa..HEAD
```

Quick branch sync check for Gearset-style branches:
```bash
# Replace names as needed
git rev-list --left-right --count origin/gs-pipeline/feature/<work-item>...origin/gs-pipeline/feature/<work-item>_-_qa
```

Org deployment status check:
```powershell
sf project deploy report --job-id <DEPLOY_ID> --target-org <alias> --json
```

Org list to avoid alias mistakes:
```powershell
sf org list --json
```

Pre-close verification bundle:
```bash
# 1) branch has expected commits
git log --oneline -n 10

# 2) PR target diff check
git fetch origin
git log --oneline origin/qa..HEAD

# 3) deploy status check (replace values)
sf project deploy report --job-id <DEPLOY_ID> --target-org <alias> --json
```

Capture lesson quickly after incident:
```bash
cd "$env:APPDATA\Code\User\memories"
git pull
# edit gotchas.md or salesforce-debugging.md with root cause + guardrail
git add .
git commit -m "lesson: <short title>"
git push
```

## npm (LWC Tests)

```bash
npm run test:unit -- componentName
npm run test:unit:coverage
npm run scan
```

## Common VS Code Tasks

Open Command Palette: Ctrl+Shift+P
Quick Open: Ctrl+P
Go to Line: Ctrl+G
Toggle Terminal: Ctrl+`

## Memory Automation

Refresh learned patterns from Copilot history:

```powershell
cd "$env:APPDATA\Code\User\memories"
.\learn-memory.ps1
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./learn-memory.sh
```

Run full weekly memory workflow (pull + learn + stage):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\run-weekly-memory.ps1
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./run-weekly-memory.sh
```

Run and finish automatically (commit + push):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\run-weekly-memory.ps1 -Commit -Push
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./run-weekly-memory.sh --commit --push
```

Domain switch prompt (use at start of a new project/chat):

```text
Domain: MuleSoft. Use domains/mulesoft and domains/general rules. Ignore Salesforce-specific deployment rules unless asked.
```

Push memory updates:

```powershell
cd "$env:APPDATA\Code\User\memories"
git add .
git commit -m "memory: weekly refresh"
git push
```

Generate task-specific memory brief (magic mode):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\summon-memory.ps1 -Task "Create API integration with OAuth and refresh token handling"
```

macOS/Linux equivalent:

```bash
cd "$HOME/Library/Application Support/Code/User/memories"
./summon-memory.sh --task "Create API integration with OAuth and refresh token handling"
```

Print one-command preflight prompt block:

```powershell
.\summon-memory.ps1 -Task "Create API integration with OAuth and refresh token handling" -Preflight
```

macOS/Linux equivalent:

```bash
./summon-memory.sh --task "Create API integration with OAuth and refresh token handling" --preflight
```

Run memory lint before promoting shared lessons:

```powershell
.\lint-memory.ps1 -IncludeCanonical
```

macOS/Linux equivalent:

```bash
./lint-memory.sh --include-canonical
```

Capture an in-flight observation (decision, blocker, progress, dead-end, insight):

```powershell
.\capture-observation.ps1 -Type decision -Domain Salesforce -Tags "deploy,qa" -Note "Promote via Gearset, not direct deploy, due to profile drift."
```

macOS/Linux equivalent:

```bash
./capture-observation.sh --type decision --domain Salesforce --tags "deploy,qa" --note "Promote via Gearset, not direct deploy, due to profile drift."
```

Synthesize the last 7 days of observations into `status-update.md`:

```powershell
.\synthesize-observations.ps1 -Days 7
```

macOS/Linux equivalent:

```bash
./synthesize-observations.sh --days 7
```

Auto-capture observations from Copilot Chat transcripts (decisions, blockers, dead-ends, insights, progress):

```powershell
.\auto-capture-observations.ps1 -SinceDays 7 -DryRun       # preview
.\auto-capture-observations.ps1 -SinceDays 7 -MaxPerRun 25 # write to log
```

Install fully automated weekly refresh (Windows Task Scheduler):

```powershell
.\install-scheduled-task.ps1 -Push                # weekly Monday 9am, auto-commit + push
.\install-scheduled-task.ps1 -Frequency Daily     # or daily refresh
.\install-scheduled-task.ps1 -Uninstall           # remove
```
