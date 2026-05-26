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

## Current baseline (v3, 60-item fixture)

```
total       : 60
accuracy    : 100%   (random baseline: 50.0%)
junk recall : 100%   (Wave 3 exit: >= 80%)
good recall : 100%   (Wave 3 exit: >= 80%)
```

Raw run of the iter-5 ruleset against v3 (before adding any new rules) was **90 / 100 / 80** -- 6 of 10 new reject shapes slipped through. Iter 6 closed them with six small rules:

- **Heading-only**: a short bullet (<= 80 chars) ending in `:` with no content after. Catches extraction artifacts like `How to confirm routing quality:` that are section headers, not memories.
- **Bare placeholder words**: relaxed the iter 4 `TODO|TBD|FIXME|WIP|XXX` rule from `\bword\b\s*[:\-]` to a bare `\bword\b` match. Catches `Required inputs: TBD. Mitigation: TODO.` where the placeholders end with `.` not `:`.
- **Aspirational vague**: `we should (be better|be able|be careful|do|try|make|consider) ...`. Catches `We should be better at writing tests` -- a wish, not a rule.
- **Vague comparison**: `(generally|usually|mostly|often) (faster|slower|better|worse|...) than`. Combines two soft signals (hedge + comparison) into one strong reject without false-positiving on either alone.
- **Apology / meta-conversation**: `^sorry,?\s` and `\bi (missed|forgot to see|didn't see) your\b`. Catches chat-thread artifacts.
- **Open-question shape**: `^(wondering|not sure) (whether|if) ...` and `\b(should i|do we need|can we use|what is the best way to)\b`. A memory that is itself an unresolved question is not yet a rule.

**100% on a 60-item fixture is still not the Wave 3 exit criterion** (>= 100 items). The honest read: the scorer now handles every shape we have labeled across 60 items spanning thirty distinct reject categories. Next loop is fixture growth v3 -> v4 (target 100), which will surface a new round of blind spots.

Iteration history:
- v1 (20-item fixture, stub rules): 75 / 100 / 50.
- Iter 1 (real-corpus extractor; reusability rule stopped penalizing bare technical vocabulary): 80 / 100 / 60.
- Iter 2 (lower baseline rewards; stronger tautology penalty; heartbeat / sync-interval pattern): 95 / 100 / 90.
- Iter 3 (contradiction-shape with phrase-overlap detection): 100 / 100 / 100 on v1.
- Iter 4 (v1 -> v2 fixture growth 20 -> 40; +6 rules for placeholder/boot/UI-event/hedge/stale-status/anecdotal-singleton; threshold tightened `>= 0` -> `> 0`): 95 / 100 / 90 on v2.
- Iter 5 (named-person Pattern A `<Name> from <dept>` + Pattern B case-sensitive `<Name> + preference verb` with tech allowlist; generic environmental-noise rule): 100 / 100 / 100 on v2.
- Iter 6 (v2 -> v3 fixture growth 40 -> 60; +6 rules for heading-only / aspirational / vague-comparison / apology-meta / open-question; relaxed bare placeholder match): **100 / 100 / 100** on v3.

Unlabeled run over the real-memory corpus (~403 items extracted from this repo): rejection went from 0% (iter 5) to 5.5% (iter 6). Every newly rejected item is a true heading-extraction artifact (`Required secrets/variables:`, `Expected output or state:`, `How to confirm routing quality:`, ...) -- bullets that should not have been ingested as memory in the first place. The new heading-only rule surfaced a real extractor bug; the scorer is doing the right thing. Score distribution on the remaining 381 kept items: min 0.1, mean 0.6, max 1.35.

## Honesty contract

- The scorer is a **stub**. It exists to make the measurement loop runnable. Do not cite the baseline as evidence the gate "works."
- The fixture is **v3** at 60 items. The roadmap target is 100. Growth is intentional — keep the keep/reject ratio balanced and the categories representative as items are added.
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

1. Add memories to `fixtures/memories-v3.jsonl` (one JSON object per line, fields: `id`, `label`, `category`, `text`). Keep the keep/reject ratio balanced.
2. Iterate the scoring rules in `score-memory.ps1`. Re-run with `-Verbose` to see which items moved.
3. Publish before/after numbers in the PR. If accuracy goes up but good-recall drops below 80%, revert.

## Not in scope here

- No dashboard yet (Wave 3 deliverable, separate PR).
- No write-path integration yet (Wave 3 deliverable, separate PR).
- No store / novelty lookup yet (depends on choosing the upstream MCP Memory wrap — Wave 5-A).
