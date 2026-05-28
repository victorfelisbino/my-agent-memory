# Wave 2 Signal Tracker

This page turns Wave 2 from passive waiting into an explicit weekly signal review.

Scope:

- Probe A: groupzer0/vs-code-agents PR #10
- Probe B: alioshr/memory-bank-mcp PR #35

Window:

- Opened: 2026-05-26
- Decision checkpoint: 2026-06-23

## Exit rule (Wave 2)

Wave 2 exits when at least one probe produces clear directional signal by 2026-06-23.

Signal means one or more of:

- Substantive maintainer review (requested changes or conceptual feedback)
- Merge
- Explicit concept rejection
- Outside engagement that references memory quality-gating value

## Weekly checkpoints

| Week ending | Probe A status | Probe B status | Outside engagement | Signal quality (0-2) | Notes | Owner |
|---|---|---|---|---:|---|---|
| 2026-05-31 | Open, awaiting first review | Open, awaiting first review | None observed yet | 0 | Baseline week; tracker created. | vf |
| 2026-06-07 | TBD | TBD | TBD | - | - | vf |
| 2026-06-14 | TBD | TBD | TBD | - | - | vf |
| 2026-06-21 | TBD | TBD | TBD | - | Final pre-decision check. | vf |

## First checkpoint runbook (week ending 2026-05-31)

Use this exact sequence so every weekly update stays comparable:

1. Open both probe PRs and capture any new maintainer comments, review requests, labels, commits, or merge state.
2. Record outside engagement (comments/reactions from non-maintainers, related cross-links, star/fork bumps if visible).
3. Classify each probe status in one line: no movement, engagement, or directional signal.
4. Set weekly `Signal quality (0-2)` using the rubric below.
5. Append evidence links in the weekly note (direct PR comment/review links).

### 2026-05-31 checkpoint entry template

Copy/paste this block into the tracker note for that week:

```md
Week ending: 2026-05-31

Probe A update:
- State: <open / reviewed / changes requested / merged / rejected>
- Evidence: <PR link(s)>
- Directional signal: <none / weak / clear>

Probe B update:
- State: <open / reviewed / changes requested / merged / rejected>
- Evidence: <PR link(s)>
- Directional signal: <none / weak / clear>

Outside engagement:
- <none or bullet list with links>

Signal quality (0-2): <0|1|2>

Operator note:
- <what changed this week, and what must happen before next checkpoint>
```

## Reusable weekly template

Use this for every week after 2026-05-31:

```md
Week ending: <YYYY-MM-DD>

Probe A update:
- State:
- Evidence:
- Directional signal:

Probe B update:
- State:
- Evidence:
- Directional signal:

Outside engagement:
-

Signal quality (0-2):

Operator note:
-
```

## Scoring rubric

- 0 = no meaningful response beyond passive state
- 1 = meaningful engagement but unclear direction
- 2 = clear directional signal (merge, explicit rejection, or actionable maintainer direction)

## Wave 4 decision packet (prepare on 2026-06-23)

Capture this in one short update:

1. Probe A outcome and evidence link
2. Probe B outcome and evidence link
3. Chosen path (A pivot, B contribute/integrate, or C archive)
4. Why this path wins versus the other two
5. 30-day execution plan

## Current status snapshot

- Probe A: open
- Probe B: open
- Net signal today: weak (monitoring)
- Next action date: 2026-05-31 checkpoint update