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
- Start date: 2026-05-25
- End date: 2026-05-29

## Kickoff status (Day 1)

- [x] Tracking issues open (#6 and #7)
- [ ] Pilot users assigned (2-3)
- [ ] Daily owner check-in time confirmed
- [ ] Benchmark task list finalized

## Daily routine (per pilot user)

1. Start day with sync and open loops review.
2. Use the framework for real tasks only (no synthetic tasks except benchmark runs).
3. Capture at least one reusable lesson from real work.
4. Mark any friction immediately in the friction log.

## 10-task benchmark set

Use recurring tasks from your real workflow. Keep them stable for all 3 modes.

| Task ID | Task description | Domain | Complexity |
|---|---|---|---|
| T1 | Triage Salesforce deploy failure from deploy id to verified fix | Salesforce | standard |
| T2 | Validate branch readiness for QA (commit diff + deploy status) | Salesforce | standard |
| T3 | Run PR risk review and produce severity-ranked findings | General | standard |
| T4 | Execute MuleSoft API rollout smoke-check workflow | MuleSoft | complex |
| T5 | Configure and verify one connector using connector template | General | trivial |
| T6 | Generate Monday business/engineering brief from current signals | General | standard |
| T7 | Capture one reusable lesson from real incident with evidence | General | trivial |
| T8 | Run compact summon-memory preflight for a cross-system task | General | standard |
| T9 | Update router intent mapping after one observed misroute | General | standard |
| T10 | Perform end-to-end workflow command run with approval gate | Salesforce | complex |

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
