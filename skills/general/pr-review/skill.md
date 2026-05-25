# Skill: PR Risk Review

## Skill

- Name: pr-risk-review
- Domain: general
- Outcome: identify high-risk changes before merge and request targeted fixes
- When to use: any non-trivial pull request
- When NOT to use: single-line typo/docs-only PRs with no behavior change

## Inputs

- Required inputs: PR link or branch diff target
- Optional inputs: incident history for related modules
- Prerequisites: local checkout or remote diff access

## Steps

1. Read change summary and classify risk areas (data, auth, deployment, state transitions, external integrations).
2. Scan diff for silent behavior changes and missing verification paths.
3. Check whether tests prove changed behavior, not just happy path.
4. Produce findings ordered by severity with concrete file references.

## Verification

- Verify command(s):
  - `gh pr view <id> --json files,commits`
  - project-specific test or lint command
- Expected signal of success: review includes reproducible high-risk findings or explicit no-findings statement with residual risk note
- Stop condition if verification fails: missing diff/test data; request required artifacts in one batched question

## Failure modes

- Symptom: review is generic and misses regressions
- Likely cause: summary-only review without code-level inspection
- Next check: inspect changed files directly and map to runtime behavior
- Fallback action: run targeted local checks for touched components

## Post-run capture

- Reusable lesson to record: recurring regression patterns and missing-test signals
- Evidence link(s): PR id and follow-up fix commit
- Confidence: medium | high
- Last verified date: YYYY-MM-DD
