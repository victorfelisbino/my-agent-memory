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
