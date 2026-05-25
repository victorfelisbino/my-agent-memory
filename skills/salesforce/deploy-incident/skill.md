# Skill: Salesforce Deploy Incident Triage

## Skill

- Name: sf-deploy-incident-triage
- Domain: salesforce
- Outcome: move a failing deployment from unknown error to verified fix quickly
- When to use: deployment failures in CI or org deploy runs
- When NOT to use: net-new feature implementation with no active failure

## Inputs

- Required inputs: target org alias, deploy id or failing command, branch/PR context
- Optional inputs: related metadata package list
- Prerequisites: Salesforce CLI authenticated and project checkout

## Steps

1. Pull deploy report and isolate first blocking error category.
2. Classify failure type (metadata mismatch, permission/set assignment, test failure, branch drift, config mismatch).
3. Run the smallest verification command that confirms the suspected root cause.
4. Apply minimal fix and rerun deployment verification.

## Verification

- Verify command(s):
  - `sf project deploy report --job-id <DEPLOY_ID> --target-org <alias> --json`
  - `sf org list --json`
  - targeted redeploy command for affected metadata
- Expected signal of success: report moves from failed to succeeded with no hidden test failures
- Stop condition if verification fails: unknown error category after first classification pass

## Failure modes

- Symptom: repeated retries with different commands but no new signal
- Likely cause: unclassified root cause or wrong org alias
- Next check: verify org alias and branch diff against deploy target branch
- Fallback action: retrieve metadata snapshot and compare against target org/branch state

## Post-run capture

- Reusable lesson to record: failure signature + fix + verification command
- Evidence link(s): deploy id, PR id, commit id
- Confidence: medium | high
- Last verified date: YYYY-MM-DD
