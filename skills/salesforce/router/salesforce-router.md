# Router: Salesforce Workflow Router

Use this router pattern to map plain-English Salesforce requests to the right workflow command.

## Router

- Name: salesforce-router
- Domain: salesforce
- Goal: route incidents, deployments, and release checks to the safest high-confidence workflow

## Routing rules

1. Map user intent keywords to command names.
2. Prefer incident triage workflow for ambiguous deploy failures.
3. Ask one batched clarification question only when critical identifiers are missing.
4. Fall back to diagnostics-first behavior when no confident route exists.

## Intent map

- Intent pattern:
  - "deploy failed", "deployment blocked", "cannot deploy", "validation failed"
  - Route to command: `skills/salesforce/commands/deploy-incident-workflow.md`
  - Confidence hints: mentions deploy id, org alias, or explicit sf deploy error

- Intent pattern:
  - "is branch ready for qa", "what commits are not in qa", "release check"
  - Route to command: `skills/general/pr-review/skill.md` plus deploy diagnostics if needed
  - Confidence hints: mentions branch compare and release readiness

- Intent pattern:
  - "what happened in this deploy", "help classify this sf error"
  - Route to command: `skills/salesforce/commands/deploy-incident-workflow.md`
  - Confidence hints: includes report snippet or stacktrace

## Missing-input policy

- Required fields to collect before execution:
  - target org alias
  - deploy id or failing command output
  - branch or PR reference
- Single batched question format:
  - "To triage this accurately, share in one reply: target org alias, deploy id (or full failing command output), and branch/PR reference."

## Safety gates

- Never auto-run risky actions without explicit confirmation.
- Always present planned steps before execution for high-risk commands.
- Never deploy to production by default.

## Verification

- How to confirm routing quality:
  - selected workflow reaches first diagnostic signal in one pass
  - no route correction needed after first execution step
- Misroute signals:
  - command cannot proceed due to mismatch with user intent
  - repeated clarifying loops with no new evidence
- Adjustment process:
  - update intent keywords and confidence hints using failed-route examples

## Telemetry notes (manual)

- Track route chosen:
- Track correction needed (yes/no):
- Track final successful command:
