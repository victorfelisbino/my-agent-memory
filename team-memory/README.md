# Team Memory

This folder is the shared memory layer for team-safe, reusable knowledge.

## Goals

- Preserve high-value lessons across engineers and projects.
- Promote only verified, reusable guardrails.
- Keep sensitive or personal context out of shared memory.

## Structure

- `inbox/`: candidate lessons awaiting review.
- `canonical/`: approved lessons ready for broad reuse.
- `templates/`: required lesson formats.
- `approval-gates.md`: promotion policy and quality gates.

## Flow

1. Draft lesson in `inbox/` using the shared template.
2. Run lint (`lint-memory.ps1` or `./lint-memory.sh`) and fix issues.
3. Validate with evidence and add owner + verification date.
4. Promote to `canonical/` only after approval gates pass.

## Rules

- No secrets, tokens, or customer PII.
- No speculative claims without explicit hypothesis label.
- No promotion without evidence and confidence metadata.
