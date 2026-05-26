# Team Memory Approval Gates

**Status (May 2026):** Aspirational. This file documents the *intended* flow for promoting a lesson from `team-memory/inbox/` to `team-memory/canonical/`. No lesson has ever actually flowed through these gates; both folders are empty. The repo has a single contributor today.

It exists so the shape is documented and so the roadmap has a concrete contract to either operationalize, repurpose, or delete. See the [roadmap](../docs/roadmap.md) (Waves 4 and 6).

A lesson should only move from `team-memory/inbox/` to `team-memory/canonical/` if all gates pass.

## Gate 1: Reusability

- Useful in at least two future scenarios.
- Not tied to one ephemeral environment detail.

## Gate 2: Evidence

- Includes at least one concrete reference:
  - PR id
  - deploy id
  - commit hash
  - incident ticket

## Gate 3: Specific guardrail

- Guardrail states exact action/check/test.
- Guardrail changes behavior, not just wording.

## Gate 4: Metadata quality

Required fields:

- Domain
- Scope
- Confidence
- Last verified date
- Owner
- Date

## Gate 5: Safety and privacy

- No secrets, credentials, or PII.
- If sensitive, keep in private memory and store a sanitized version for team memory.

## Gate 6: Freshness

- Last verified date is within 180 days.
- If older, either re-verify or downgrade confidence before promotion.

## Promotion checklist (if/when this flow is ever used)

1. Draft exists in `team-memory/inbox/`.
2. Lint passes.
3. Reviewer confirms all gates.
4. Move file into `team-memory/canonical/`.
5. Add short note to `decision-journal.md` if process changed.
