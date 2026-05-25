# Router Template

Use this router pattern when you want users to describe a problem in plain English and automatically route to the best command.

## Router

- Name:
- Domain:
- Goal:

## Routing rules

1. Map user intent keywords to command names.
2. Prefer safest command when confidence is low.
3. Ask one batched clarification question only when required inputs are missing.
4. Fall back to a diagnostic command when no confident match exists.

## Intent map

- Intent pattern:
  - Route to command:
  - Confidence hints:

## Missing-input policy

- Required fields to collect before execution:
- Single batched question format:

## Safety gates

- Never auto-run risky actions without explicit confirmation.
- Always present planned steps before execution for high-risk commands.

## Verification

- How to confirm routing quality:
- Misroute signals:
- Adjustment process:

## Telemetry notes (manual)

- Track route chosen:
- Track correction needed (yes/no):
- Track final successful command:
