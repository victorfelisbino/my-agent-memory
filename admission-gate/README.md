# Admission gate

The quality gate for memory writes. Today this directory contains the **measurement harness** for Wave 3 — a labeled fixture and a baseline scorer. It is not yet wired into any agent's write path.

## Why this exists

mem0 issue [#4573](https://github.com/mem0ai/mem0/issues/4573) documents a 97.8% junk rate in real-world LLM memory pipelines. Every "store everything by default" system in the landscape has the same problem. Until a memory pipeline can credibly reject low-value writes, recall numbers are theater.

The Wave 3 exit criterion in the [roadmap](../docs/roadmap.md) is:

> Given a sample of 100 memories (50 good, 50 from the documented junk categories), the gate correctly rejects 80%+ of junk while keeping 80%+ of good memories.

The kill switch fires if the scoring function cannot beat random (50/50) on the test set. This harness exists so that bar can be measured honestly, not asserted.

## What is here today

- [`fixtures/memories-v1.jsonl`](fixtures/memories-v1.jsonl) -- 20 labeled memories (10 keep, 10 reject). Reject categories cover the documented junk shapes: boot noise, heartbeat, transient task state, hallucinated profile, vague non-actionable, self-referential, world noise, project-private without portable lesson, tautology, contradiction-in-one-line.
- [`fixtures/memories-v5.jsonl`](fixtures/memories-v5.jsonl) -- iter-10 fixture. v4 + 8 contradiction-against-store items (4 contradicts, 4 reinforces). Only meaningful when run with `-Store fixtures/store-anchors.jsonl`.
- [`fixtures/memories-v6.jsonl`](fixtures/memories-v6.jsonl) -- iter-11 fixture. v5 + 8 feedback-loop items (4 distinct-topic keeps, 4 paraphrase-of-recalled rejects). Only meaningful when run with both `-Store fixtures/store-anchors.jsonl` AND `-Recalled fixtures/recalled-session.jsonl`.
- [`fixtures/store-anchors.jsonl`](fixtures/store-anchors.jsonl) -- 6 anchor memories representing what the store "already believes." Used by the iter-10 contradiction-against-store check.
- [`fixtures/recalled-session.jsonl`](fixtures/recalled-session.jsonl) -- 4 memories representing what was surfaced ("recalled") earlier in the current session. Used by the iter-11 feedback-loop check to reject re-ingestion of a memory the agent literally just read.
- [`score-memory.ps1`](score-memory.ps1) -- baseline scorer (PowerShell) with stub rules across the four Wave 3 dimensions: reusability, atomicity, novelty (wired to contradiction-against-store when `-Store` is provided **and** feedback-loop when `-Recalled` is provided -- iter 11), actionability. Emits per-memory decisions and a summary block. Supports an `-Unlabeled` mode for scoring real, unlabeled corpora and reporting score distribution + lowest-scored items for human inspection.
- [`score_memory.py`](score_memory.py) -- **Python port** of the same scorer (iter 9), with iter-10 `--store` and iter-11 `--recalled` parity. Faithful re-implementation of every rule (same regex set, same weights, same threshold, same contradiction-against-store and feedback-loop logic). Cross-language parity is enforced by [`parity-check.ps1`](parity-check.ps1) + [`parity-emit.ps1`](parity-emit.ps1) in CI: same fixture in, same per-item keep/reject out, with or without `--store` / `--recalled`. The Python port exists so the same rules can be embedded as middleware in pipelines that are not PowerShell-native (mem0, langchain, custom MCP servers, etc.).
- [`extract-corpus.ps1`](extract-corpus.ps1) — pulls top-level bullets from real .md files in the repo into a JSONL corpus, so the scorer can be aimed at real memory (not just the synthetic fixture). Output is gitignored — regenerate on demand.
- [`score-memory.sh`](score-memory.sh) — parity stub that delegates to `pwsh`.

## Current baseline (v4, 100-item fixture — Wave 3 exit-criterion size)

```
total       : 100
accuracy    : 100%  (random baseline: 50.0%)
junk recall : 100%  (Wave 3 exit: >= 80%)
good recall : 100%  (Wave 3 exit: >= 80%)
```

v4 is the first fixture at the Wave 3 exit-criterion size (100 items, 50 keep / 50 reject). **Both exit thresholds are met with full headroom** -- iter 8 closed the 9 named misses from iter 7 with 9 small rules and no keep regressions. This does *not* mean the scorer is finished; the next gap is dimensional (no novelty lookup, no contradiction-against-store, no write-path integration), not fixture coverage.

Iter 7 baseline on v4 was **91 / 100 / 82** with 9 named misses. Iter 8 added one rule per miss:

- **Pop-culture / inside-joke**: `\breminds me of (that one|the one|a|an|that|this)? (episode|movie|show|scene|chapter|moment|time)\b`. The bullet is an analogy without a transferable rule.
- **Confidence-only**: `\bi (am|'m) (very|highly|super|really|quite|extremely|absolutely)? (confident|sure|certain|positive)\b`. A confidence assertion is not itself a rule.
- **Pure task-restatement**: `\bas requested\b`. Echoing the request back as the memory carries no new information.
- **Empty agreement**: `^yes,? (that|this) (approach|plan|idea|sounds|works|is)\b` or `\bwe should definitely\b`. Agreement without content.
- **Self-praise**: `\b(one of my|my) (best|finest|cleanest|favorite) (implementation|implementations|work|code|solution|solutions|design|designs)\b` or `\bin my opinion\b`.
- **Vague urgency**: combines an urgency adverb (`urgent`/`urgently`) with a softener (`important`/`critical`/`as soon as possible`/`asap`). Either alone could appear in legitimate memory; the stack means alarm without action.
- **Number-only summary**: `^(total|summary|stats|counts|metrics)\s*[:\-]`. Tallies, not rules.
- **Imperative-only short**: `length < 80` AND opens with a bare action verb (`Run|Click|Open|Build|Deploy|...`) AND no rule-shape qualifier (`if|when|because|unless|always|never|prefer|since|so that`). Kept memories that open with `Prefer/Always/Never/When/Before/After` are excluded by the verb list; any kept memory that opens with a bare imperative carries enough length or qualifier to escape.
- **Self-correction loop**: `^wait,? actually\b` or `\blet me (think|reconsider|reanalyze) (again|that|this)\b` or `\blet me reconsider\b`. The bullet is mid-thought, not a resolved rule.

Real-corpus rejection went from 0.3% (iter 7, 1 of 381) to **1.0% (4 of 381)**. All 4 are defensible: the `Status: ...` playbook snapshot from iter 7, plus 3 personal-goal TODO bullets from `goals.md` (`Run weekly memory workflow ...`, `Refresh scoreboard ...`, `Run one retrieval quality check ...`) that are exactly the imperative-only-short shape the new rule targets. These are project-private checklist items, not portable memories.

Iter 7 baseline detail (kept for context). Raw run of the iter-6 ruleset against v4 (before adding any new rules) was **82 / 100 / 64** -- 18 of 20 new reject shapes slipped through. Iter 7 closed nine of them with eight small rules:

- **Status-update ping**: `^status:` / `^update:` lead-ins and phrases like `nothing to report`, `all systems operational/nominal/green`, `everything is fine`, `just a (quick) update / check-in`. Catches `Status: OK. Nothing to report.` and `GitHub status page shows all systems operational`.
- **Self-reminder**: `\bremember to\b`. Personal notes (`Remember to drink water during long debugging sessions`) are not portable rules.
- **Hedge stacking**: requires two hedges in one bullet, one from `(might|may|could|perhaps)` and one from `(possibly|maybe|probably|likely)`. Single hedges appear in legitimate memory; a stack signals pure speculation.
- **Personal scheduling**: `\bi (have|got|'ve got) (a)? (meeting|standup|call|sync|1:1|appointment)\b`. Calendar status, not memory.
- **Greeting / sign-off**: `^(hi|hello|hey) (team|all|everyone|folks)\b` and `hope (everyone|you all) is doing well`. Chat-thread artifacts.
- **Side-note / off-topic**: `\b(side note|off topic|btw|by the way|fun fact)\b`. The bullet is explicitly tangential.
- **Pure user-speculation**: `(the )?(user|customer|client) (probably|likely|maybe|presumably|might have)`. Guessing about intent is not memory.
- **Restated documentation**: `according to (the|our)? (\w+ )? (docs|documentation|spec|specification|manual|readme)`. Pointing at docs is not a memory; the rule extracted from the docs would be.

Also shipped in iter 7: the `extract-corpus.ps1` extractor now skips heading-only sub-bullets (`^.{1,80}:\s*$`) so the real-corpus smoke no longer rejects 22 extractor artifacts. Real-corpus rejection went from 5.5% (iter 6) back to 0.3% (iter 7) -- one bullet, a `Status: ...` project snapshot from a playbook, defensibly rejected.

**Documented iter-9 targets (none on v4 -- next is dimensional, not fixture coverage):** no novelty lookup (deduplication against existing store), no contradiction-against-store check, no write-path integration, no dashboard. v4 is saturated; further fixture growth without a real store check would be measurement theater.

Iteration history:
- v1 (20-item fixture, stub rules): 75 / 100 / 50.
- Iter 1 (real-corpus extractor; reusability rule stopped penalizing bare technical vocabulary): 80 / 100 / 60.
- Iter 2 (lower baseline rewards; stronger tautology penalty; heartbeat / sync-interval pattern): 95 / 100 / 90.
- Iter 3 (contradiction-shape with phrase-overlap detection): 100 / 100 / 100 on v1.
- Iter 4 (v1 -> v2 fixture growth 20 -> 40; +6 rules for placeholder/boot/UI-event/hedge/stale-status/anecdotal-singleton; threshold tightened `>= 0` -> `> 0`): 95 / 100 / 90 on v2.
- Iter 5 (named-person Pattern A `<Name> from <dept>` + Pattern B case-sensitive `<Name> + preference verb` with tech allowlist; generic environmental-noise rule): 100 / 100 / 100 on v2.
- Iter 6 (v2 -> v3 fixture growth 40 -> 60; +6 rules for heading-only / aspirational / vague-comparison / apology-meta / open-question; relaxed bare placeholder match): 100 / 100 / 100 on v3.
- Iter 7 (v3 -> v4 fixture growth 60 -> 100 -- exit-criterion size; +8 rules for status-update-ping / self-reminder / hedge-stacking / personal-scheduling / greeting-signoff / side-note / user-speculation / restated-docs; extractor now drops heading-only sub-bullets): 91 / 100 / 82 on v4; real corpus 0.3% rejection.
- Iter 8 (+9 rules for pop-culture / confidence-only / task-restatement / empty-agreement / self-praise / vague-urgency / number-only-summary / imperative-only-short / self-correction-loop; no keep regressions): 100 / 100 / 100 on v4; real corpus 1.0% rejection (3 of 4 new rejects are personal-goal TODO bullets correctly flagged as imperative-only-short).
- Iter 9 (**standalone Python port** of the scorer at `score_memory.py`; cross-language parity test `parity-check.ps1` + `parity-emit.ps1`; CI now runs both scorers AND a per-item decision diff on v4 and on the live real-memory corpus): 100 / 100 / 100 on v4 in both languages; 381 / 381 decisions match on the real corpus. No rules changed; the contract is now "PS and Python must agree on every item."
- Iter 10 (**contradiction-against-store**; v4 -> v5 fixture growth 100 -> 108: +4 reject contradictions, +4 keep reinforces; new `-Store` / `--store` flag in both scorers loads an anchor JSONL; novelty dimension wired to a polarity+subject overlap check; -2.0 penalty when same subject + opposite polarity; parity extended): **108 / 108 / 108** with store on v5 in both languages; v4 baseline unchanged at **100 / 100 / 100** (no `-Store` -> novelty stays 0.0); real corpus parity: **381 / 381** with and without store.
- Iter 11 (**feedback-loop prevention**; v5 -> v6 fixture growth 108 -> 116: +4 distinct-topic keeps, +4 feedback-loop rejects; new `-Recalled` / `--recalled` flag in both scorers loads a recalled-session JSONL; novelty dimension extended to flag candidates that mirror an already-surfaced memory; -2.0 penalty when same subject + same polarity AND >= 4 shared content tokens; parity extended): **116 / 116 / 116** with store + recalled on v6 in both languages; v4 and v5 baselines unchanged; real corpus parity: **381 / 381** with store + recalled (no real bullet collides with the recalled set)._
  Why two overlap thresholds: contradiction-against-store uses >= 2 shared tokens because opposite polarity already makes false positives unlikely; feedback-loop uses >= 4 because same polarity needs a higher bar to distinguish redundancy ("you just read this") from mere topic similarity (two distinct memories about the same area).
- Iter 12 (**dashboard slice 1**; new `-LogTo` / `--log-to` flag in both scorers appends one JSON line per scored item to a shared log; new [`render-dashboard.ps1`](render-dashboard.ps1) reads any log produced by either scorer and emits a single self-contained `dashboard.html` (summary tiles, top rejection reasons, contradiction-against-store hits + anchor ids, feedback-loop hits + recall ids, 50 most recent decisions); log + dashboard are gitignored, local-only audit tool, no server, no JS framework; CI smoke step runs PS+Py with logging, renders the dashboard, and asserts the expected sections are present). No rules changed; all baselines and parity numbers unchanged.

## Honesty contract

- The scorer is a **stub**. It exists to make the measurement loop runnable. Do not cite the baseline as evidence the gate "works."
- The fixture is **v4** at 100 items — Wave 3 exit-criterion size. Hitting the criterion does not mean the scorer is finished; the 9 named iter-8 targets above are the honest gap.
- Every change to the scorer must re-publish the accuracy / good-recall / junk-recall triple on this fixture in the PR description. Improving accuracy by sacrificing good-recall is regression, not progress.

## How to run

```powershell
pwsh ./admission-gate/score-memory.ps1                              # labeled summary (PowerShell)
pwsh ./admission-gate/score-memory.ps1 -Verbose                     # per-memory table
pwsh ./admission-gate/score-memory.ps1 -FailUnder 75                # CI gate: fail if accuracy < 75%
pwsh ./admission-gate/score-memory.ps1 \`
  -Fixture admission-gate/fixtures/memories-v5.jsonl \`
  -Store   admission-gate/fixtures/store-anchors.jsonl              # contradiction-against-store (iter 10)
pwsh ./admission-gate/score-memory.ps1 \`
  -Fixture  admission-gate/fixtures/memories-v6.jsonl \`
  -Store    admission-gate/fixtures/store-anchors.jsonl \`
  -Recalled admission-gate/fixtures/recalled-session.jsonl          # + feedback-loop (iter 11)
python admission-gate/score_memory.py                               # labeled summary (Python port)
python admission-gate/score_memory.py --fail-under 85               # Python CI gate
python admission-gate/score_memory.py \`
  --fixture admission-gate/fixtures/memories-v5.jsonl \`
  --store   admission-gate/fixtures/store-anchors.jsonl             # Python contradiction-against-store
python admission-gate/score_memory.py \`
  --fixture  admission-gate/fixtures/memories-v6.jsonl \`
  --store    admission-gate/fixtures/store-anchors.jsonl \`
  --recalled admission-gate/fixtures/recalled-session.jsonl         # Python + feedback-loop
pwsh ./admission-gate/parity-check.ps1                              # PS vs Python per-item decision diff
pwsh ./admission-gate/parity-check.ps1 \`
  -Fixture admission-gate/fixtures/memories-v5.jsonl \`
  -Store   admission-gate/fixtures/store-anchors.jsonl              # parity with store
pwsh ./admission-gate/parity-check.ps1 \`
  -Fixture  admission-gate/fixtures/memories-v6.jsonl \`
  -Store    admission-gate/fixtures/store-anchors.jsonl \`
  -Recalled admission-gate/fixtures/recalled-session.jsonl          # parity with store + recalled
pwsh ./admission-gate/extract-corpus.ps1                            # derive real-memory.jsonl
pwsh ./admission-gate/score-memory.ps1 \`
  -Fixture admission-gate/fixtures/real-memory.jsonl \`
  -Unlabeled -ShowWorst 20                                          # unlabeled distribution
```

Exit codes: `0` ok, `2` fixture missing or malformed, `3` accuracy below `-FailUnder`, `4` parity diff between PS and Python.

## How to extend

1. Add memories to `fixtures/memories-v4.jsonl` (one JSON object per line, fields: `id`, `label`, `category`, `text`). Keep the keep/reject ratio balanced.
2. Iterate the scoring rules in `score-memory.ps1` **and** `score_memory.py` together — cross-language parity is enforced in CI, so a one-sided change will fail the build. Re-run with `-Verbose` / `--verbose` to see which items moved.
3. Publish before/after numbers in the PR. If accuracy goes up but good-recall drops below 80%, revert.

## Not in scope here

- No write-path integration yet (Wave 3 deliverable, separate PR).
- Contradiction-against-store (iter 10) and feedback-loop (iter 11) both use a polarity+subject-overlap heuristic, not embeddings. Good for the obvious "always X / never X" inversion and verbatim-paraphrase shapes; would not catch a deeply rephrased contradiction or a synonym-swapped re-ingestion with no shared content tokens.

## Dashboard (iter 12)

Local, static HTML view of what the scorer has been deciding. No server, no JS framework, no external assets — just a single file you open in a browser. The log and the dashboard are gitignored; this is a local audit tool, not a publish target.

```powershell
# 1. Score with logging enabled (PS and/or Python; both write the same JSON shape).
pwsh ./admission-gate/score-memory.ps1 \`
  -Fixture  admission-gate/fixtures/memories-v6.jsonl \`
  -Store    admission-gate/fixtures/store-anchors.jsonl \`
  -Recalled admission-gate/fixtures/recalled-session.jsonl \`
  -LogTo    admission-gate/logs/scoring.jsonl
python admission-gate/score_memory.py \`
  --fixture  admission-gate/fixtures/memories-v6.jsonl \`
  --store    admission-gate/fixtures/store-anchors.jsonl \`
  --recalled admission-gate/fixtures/recalled-session.jsonl \`
  --log-to   admission-gate/logs/scoring.jsonl

# 2. Render. Reads any JSONL log produced by either scorer.
pwsh ./admission-gate/render-dashboard.ps1                          # -> admission-gate/dashboard.html

# 3. Open.
Start-Process ./admission-gate/dashboard.html
```

What the dashboard shows: summary tiles (total scored, kept, rejected, contradiction-against-store hits, feedback-loop hits), top rejection reasons (primary reason fragment, magnitude-stripped so similar reasons group), every contradiction-against-store hit with its anchor id, every feedback-loop hit with its recall id, and the 50 most recent decisions newest-first. The log is append-only; delete `admission-gate/logs/scoring.jsonl` to start fresh.

Iter-12 honesty note: this is "dashboard slice 1." No live refresh, no time-series chart yet, no staleness view (memories themselves carry no timestamps yet). The point is to make the scorer's decisions reviewable, not pretty.
