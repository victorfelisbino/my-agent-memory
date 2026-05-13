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

Run full weekly memory workflow (pull + learn + stage):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\run-weekly-memory.ps1
```

Run and finish automatically (commit + push):

```powershell
cd "$env:APPDATA\Code\User\memories"
.\run-weekly-memory.ps1 -Commit -Push
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
