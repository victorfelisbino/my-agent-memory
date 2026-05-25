# Workflow Command: Salesforce Deploy Incident Workflow

## Command

- Name: sf-deploy-incident-workflow
- Domain: salesforce
- Purpose: triage a failing deployment to verified resolution with minimal retries
- Trigger phrases (what a user might naturally say):
  - "deployment failed in staging"
  - "prod deploy is blocked"
  - "sf deploy report shows errors"
  - "help me triage this deploy incident"
- Skills used:
  - `skills/salesforce/deploy-incident/skill.md`

## Inputs

- Required:
  - target org alias
  - deploy id or exact failing command output
  - branch or PR context
- Optional:
  - package/file scope
  - prior deploy ids from same branch
- Required connectors/tools:
  - Salesforce CLI (`sf`)
  - git
- Optional connectors/tools:
  - CI run logs

## Workflow steps

1. Intake and scope
   - Confirm target org, deploy id, and branch/PR.
   - State expected outcome in one line: "deployment succeeds with no hidden test failures."
2. Execute skill chain in order
   - Run deploy report retrieval and classify first blocking error.
   - Run one minimal verification command for suspected root cause.
   - Apply smallest safe fix.
   - Re-run targeted verification, then full deploy verification.
3. Pause at approval gate before any risky or state-changing action
   - Pause before modifying metadata, changing permissions, or running broad redeploy.
4. Complete and summarize outcomes
   - Return root cause, fix, verification evidence, and next safeguards.

## Approval gates

- Gate 1: before applying any metadata or permission change.
- Gate 2: before running a full redeploy to target org.
- Actions that must never run without explicit confirmation:
  - destructive metadata operations
  - mass permission changes
  - deployment to production alias

## Graceful degradation

- If required connector fails:
  - If `sf` is unavailable, stop and return setup recovery steps first.
- If optional connector fails:
  - If CI logs are unavailable, continue with org deploy reports and local branch evidence.
- Reduced-mode output and caveats:
  - provide best-effort classification with explicit uncertainty and required missing artifacts.

## Verification

- Verify command(s):
  - `sf org list --json`
  - `sf project deploy report --job-id <DEPLOY_ID> --target-org <alias> --json`
  - `git log --oneline origin/qa..HEAD`
  - targeted `sf project deploy start ...` for affected metadata
- Expected signal:
  - deploy report status transitions to succeeded
  - test and validation sections show no hidden failures
- Stop condition if verification fails:
  - two consecutive retries without new diagnostic signal

## Output contract

- Summary format:
  - incident signature
  - root cause category
  - fix applied
  - verification evidence
  - prevention guardrail
- Artifacts produced:
  - command transcript summary
  - reusable lesson candidate
- Evidence links:
  - deploy id, PR id, commit id

## Post-run memory capture

- Reusable lesson to record:
  - failure signature + root cause + verify command + guardrail
- Confidence: low | medium | high
- Last verified date: YYYY-MM-DD
