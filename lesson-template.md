# Lesson Template

Use this after each failure or near-miss.

## [P0|P1|P2] Short title

- Domain: general | salesforce | mulesoft
- Scope: session | user | org
- What failed:
- Root cause category: branch process | metadata mismatch | permission model | code defect | deployment process
- Detection that would have caught it earlier:
- Guardrail to prevent recurrence:
- Evidence: deploy id / PR / commit
- Stable identifiers: file path(s) / deploy id / PR id / ticket id
- Confidence: low | medium | high
- Last verified date:
- Re-verify by:
- Owner:
- Date:

## Ready to add?

When complete, copy the distilled guardrail to gotchas.md or salesforce-debugging.md.

## Quality check before saving

- Is this reusable beyond this one incident?
- Is this verified rather than speculative?
- Is the guardrail behaviorally specific (what to run/check/test)?
