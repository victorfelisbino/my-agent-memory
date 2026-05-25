# Skill: MuleSoft API Rollout

## Skill

- Name: mulesoft-api-rollout
- Domain: mulesoft
- Outcome: rollout API changes with controlled risk and verified integration behavior
- When to use: RAML or flow changes that affect consumers
- When NOT to use: isolated local refactor with no API contract impact

## Inputs

- Required inputs: environment target, API version, deployment artifact reference
- Optional inputs: consumer compatibility matrix
- Prerequisites: access to Anypoint/CloudHub deployment and logs

## Steps

1. Validate contract-impact scope (breaking vs non-breaking changes).
2. Deploy to target environment with version traceability.
3. Run smoke checks on critical endpoints and auth flows.
4. Confirm downstream integration behavior and error-rate baseline.

## Verification

- Verify command(s):
  - environment-specific deploy command
  - smoke test script or endpoint checks
  - log/error-rate query in monitoring tool
- Expected signal of success: endpoints pass smoke checks and error profile remains within expected threshold
- Stop condition if verification fails: breaking contract impact without migration path

## Failure modes

- Symptom: deployment succeeds but consumers fail shortly after
- Likely cause: contract drift or untested auth/rate-limit path
- Next check: compare request/response schema and auth configuration against consumer assumptions
- Fallback action: rollback to last known-good version and open compatibility remediation task

## Post-run capture

- Reusable lesson to record: contract change impact pattern + validation checklist
- Evidence link(s): deployment id, monitoring snapshot, incident ticket
- Confidence: medium | high
- Last verified date: YYYY-MM-DD
