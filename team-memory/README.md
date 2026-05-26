# Team Memory

**Status (May 2026):** Aspirational. This folder structure is reserved for a future multi-contributor workflow. Today the repo has a single contributor, `inbox/` and `canonical/` are empty, and no lesson has actually been promoted through this flow.

It exists in the tree so the shape is visible and so the [roadmap](../docs/roadmap.md) has a concrete thing to either populate, repurpose, or delete. Don't treat anything in `canonical/` as endorsed by a team — there is no team yet.

## Intended structure

- `inbox/`: candidate lessons awaiting review.
- `canonical/`: approved lessons ready for broad reuse.
- `templates/`: required lesson formats.
- `approval-gates.md`: promotion policy and quality gates.

## Intended flow

1. Draft lesson in `inbox/` using the shared template.
2. Run lint (`lint-memory.ps1` or `./lint-memory.sh`) and fix issues.
3. Validate with evidence and add owner + verification date.
4. Promote to `canonical/` only after approval gates pass.

## Rules (whenever this is actually used)

- No secrets, tokens, or customer PII.
- No speculative claims without explicit hypothesis label.
- No promotion without evidence and confidence metadata.
