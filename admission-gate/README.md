# Admission gate

The quality gate for memory writes. Today this directory contains the **measurement harness** for Wave 3 — a labeled fixture and a baseline scorer. It is not yet wired into any agent's write path.

## Why this exists

mem0 issue [#4573](https://github.com/mem0ai/mem0/issues/4573) documents a 97.8% junk rate in real-world LLM memory pipelines. Every "store everything by default" system in the landscape has the same problem. Until a memory pipeline can credibly reject low-value writes, recall numbers are theater.

The Wave 3 exit criterion in the [roadmap](../docs/roadmap.md) is:

> Given a sample of 100 memories (50 good, 50 from the documented junk categories), the gate correctly rejects 80%+ of junk while keeping 80%+ of good memories.

The kill switch fires if the scoring function cannot beat random (50/50) on the test set. This harness exists so that bar can be measured honestly, not asserted.

## What is here today

- [`fixtures/memories-v1.jsonl`](fixtures/memories-v1.jsonl) — 20 labeled memories (10 keep, 10 reject). Reject categories cover the documented junk shapes: boot noise, heartbeat, transient task state, hallucinated profile, vague non-actionable, self-referential, world noise, project-private without portable lesson, tautology, contradiction-in-one-line.
- [`score-memory.ps1`](score-memory.ps1) — baseline scorer with stub rules across the four Wave 3 dimensions: reusability, atomicity, novelty (stubbed), actionability. Emits per-memory decisions and a summary block. Supports an `-Unlabeled` mode for scoring real, unlabeled corpora and reporting score distribution + lowest-scored items for human inspection.
- [`extract-corpus.ps1`](extract-corpus.ps1) — pulls top-level bullets from real .md files in the repo into a JSONL corpus, so the scorer can be aimed at real memory (not just the synthetic fixture). Output is gitignored — regenerate on demand.
- [`score-memory.sh`](score-memory.sh) — parity stub that delegates to `pwsh`.

## Current baseline (v1, 20-item fixture)

```
total       : 20
accuracy    : 95%   (random baseline: 50.0%)
junk recall : 90%   (Wave 3 exit: >= 80%)
good recall : 100%  (Wave 3 exit: >= 80%)
```

Clears the 80% percentage threshold on accuracy, good recall, and junk recall. **This is not the Wave 3 exit criterion** — the exit criterion also requires the fixture to be ≥100 items (today: 20). One documented miss remains on v1: contradiction-shape (`always X; never X` on a single line) gets +0.75 of actionability credit from the verbs "always" and "never" themselves, partially cancelling the structural penalty. Closing this safely requires distinguishing `always X; never X` (contradiction) from `always X; never Y` (legitimate dual-rule guidance) and is the next iteration.

Iteration history:
- v1 (20-item fixture, stub rules): 75 / 100 / 50.
- Iter 1 (real-corpus extractor; reusability rule stopped penalizing bare technical vocabulary like "branch"/"repo"/"src"): 80 / 100 / 60.
- Iter 2 (lower baseline rewards so vague items can dip negative; tautology penalty -0.5 → -1.0; new heartbeat / still-alive / sync-interval pattern): **95 / 100 / 90**.

Unlabeled run over the current real-memory corpus (~429 items extracted from this repo): 0% rejection, mean ~0.65, all items above the keep threshold. Lowest-scored items are extraction artifacts (heading-only bullets, template placeholders) rather than real memory — useful signal for where to tighten the extractor next, not evidence the scorer is rejecting real value.

## Honesty contract

- The scorer is a **stub**. It exists to make the measurement loop runnable. Do not cite the baseline as evidence the gate "works."
- The fixture is **v1** at 20 items. The roadmap target is 100. Growth is intentional — keep the keep/reject ratio balanced and the categories representative as items are added.
- Every change to the scorer must re-publish the accuracy / good-recall / junk-recall triple on this fixture in the PR description. Improving accuracy by sacrificing good-recall is regression, not progress.

## How to run

```powershell
pwsh ./admission-gate/score-memory.ps1                              # labeled summary
pwsh ./admission-gate/score-memory.ps1 -Verbose                     # per-memory table
pwsh ./admission-gate/score-memory.ps1 -FailUnder 75                # CI gate: fail if accuracy < 75%
pwsh ./admission-gate/extract-corpus.ps1                            # derive real-memory.jsonl
pwsh ./admission-gate/score-memory.ps1 \`
  -Fixture admission-gate/fixtures/real-memory.jsonl \`
  -Unlabeled -ShowWorst 20                                          # unlabeled distribution
```

Exit codes: `0` ok, `2` fixture missing or malformed, `3` accuracy below `-FailUnder`.

## How to extend

1. Add memories to `fixtures/memories-v1.jsonl` (one JSON object per line, fields: `id`, `label`, `category`, `text`). Keep the keep/reject ratio balanced.
2. Iterate the scoring rules in `score-memory.ps1`. Re-run with `-Verbose` to see which items moved.
3. Publish before/after numbers in the PR. If accuracy goes up but good-recall drops below 80%, revert.

## Not in scope here

- No dashboard yet (Wave 3 deliverable, separate PR).
- No write-path integration yet (Wave 3 deliverable, separate PR).
- No store / novelty lookup yet (depends on choosing the upstream MCP Memory wrap — Wave 5-A).
