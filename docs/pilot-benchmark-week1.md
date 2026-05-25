# Pilot + Benchmark Runbook (Week 1)

This runbook is used for:
- Issue #6: Pilot Week 1
- Issue #7: Token benchmark (10 repeat tasks)

## Purpose

Validate two outcomes in one week:
1. The framework improves day-to-day context continuity for real users.
2. Compact memory mode reduces total token usage without quality regression.

## Team

- Owner: @victorfelisbino
- Pilot users: add 2-3 handles
- Start date: YYYY-MM-DD
- End date: YYYY-MM-DD

## Daily routine (per pilot user)

1. Start day with sync and open loops review.
2. Use the framework for real tasks only (no synthetic tasks except benchmark runs).
3. Capture at least one reusable lesson from real work.
4. Mark any friction immediately in the friction log.

## 10-task benchmark set

Use recurring tasks from your real workflow. Keep them stable for all 3 modes.

| Task ID | Task description | Domain | Complexity |
|---|---|---|---|
| T1 |  |  |  |
| T2 |  |  |  |
| T3 |  |  |  |
| T4 |  |  |  |
| T5 |  |  |  |
| T6 |  |  |  |
| T7 |  |  |  |
| T8 |  |  |  |
| T9 |  |  |  |
| T10 |  |  |  |

## Modes to run

Run each task in all modes:
- no-brief
- full-brief
- compact-brief

## Benchmark tracking table

| Date | User | Task ID | Mode | Turns | Total tokens | Time to first correct action (min) | Retries | Manual override | Outcome quality (pass/fail) | Notes |
|---|---|---|---|---:|---:|---:|---:|---|---|---|
|  |  |  | no-brief |  |  |  |  |  |  |  |
|  |  |  | full-brief |  |  |  |  |  |  |  |
|  |  |  | compact-brief |  |  |  |  |  |  |  |

## Friction log

| Date | User | Friction point | Impact | Suggested fix |
|---|---|---|---|---|
|  |  |  |  |  |

## Midweek checkpoint (Day 3)

- What is working immediately:
- Highest friction item:
- Any privacy/safety concern:
- Should task definitions be adjusted for consistency:

## Final checkpoint (Day 5)

## Quality summary
- Median turns by mode:
- Retry rate by mode:
- Outcome quality pass rate by mode:

## Token summary
- Median total tokens by mode:
- Compact vs full token delta (%):
- Compact vs no-brief token delta (%):

## Decision

Adopt compact-by-default only if all are true:
1. Median turns do not increase.
2. Retry count does not increase.
3. Total tokens drop by at least 25% on standard tasks.

## Follow-up actions

- Promote verified reusable lessons to shared memory docs.
- Update router/task-type classifier rules based on misroutes.
- Open follow-up issue for any unresolved friction > medium impact.
