# Site Redesign: Quality Gate Identity

**Date:** 2026-05-26
**Status:** Approved
**Scope:** Rewrite the published mkdocs site to lead with the "quality gate for AI agent memory" identity instead of the personal knowledge management narrative.

---

## Context

The project has two identities that aren't aligned:
- **README/roadmap:** "The quality gate for AI agent memory" — a product that filters garbage from memory stores.
- **Published site:** "A brain that learns once" — a personal two-repo knowledge management system.

Wave 3 just completed with 100/100/100 accuracy on a 100-item fixture, the gate integrated into every write path, and a Python scorer ready for middleware use. The site should reflect what's actually been built.

## Audience

Developers who use coding agents daily (Copilot, Cursor, Cline, Claude Code) and are frustrated with garbage memory accumulation.

## Primary CTA

"Try the scorer locally" — clone the repo, run the Python scorer against your own corpus, see results in 60 seconds.

---

## Navigation Structure

**Current:** Home | Start | How it works | Where this is going | What this brain knows | Notes

**New:**
```yaml
nav:
  - Home: index.md
  - The Gate:
      - How it works: the-gate.md
      - Evidence: evidence.md
  - Try It: try-it.md
  - Background:
      - Origin story: framework-purpose.md
      - Two-repo pattern: framework-scope.md
      - Memory adoption playbook: memory-adoption-playbook.md
      - Principles: principles-ways-of-thinking.md
      - Copilot auto-mode: copilot-auto-mode.md
      - Quick restart routine: quick-restart-routine.md
      - Anti-hallucination skill: anti-hallucination-skill.md
  - Status & Direction:
      - Status (what's real today): status.md
      - Roadmap: roadmap.md
      - Competence map: competence-map.md
      - Competitive landscape (May 2026): competitive-landscape-2026-05.md
      - Memory ecosystem research: memory-ecosystem-research-2026-05-15.md
```

**Pages killed:** `should-you-use-this.md` removed from nav (content absorbed into Try It and landing).

**Pages created:**
- `docs/the-gate.md` — how the admission scorer works
- `docs/evidence.md` — accuracy numbers, methodology, before/after examples
- `docs/try-it.md` — 60-second local quickstart

---

## Page Designs

### Landing Page (docs/index.md) — FULL REWRITE

**1. Hero (landing-shell component):**
- Headline: "Stop your agent's memory from becoming 97% garbage."
- Lead: mem0's documented 97.8% junk rate. Nobody filters. We built the part that says no. 100/100/100 accuracy on a 100-item labeled fixture, integrated into every write path.
- Pills: `100/100/100 accuracy` | `4-dimension scoring` | `PowerShell & Python`
- CTAs: "Try the scorer" (primary, links to try-it.md) | "See the evidence" (secondary, links to evidence.md)

**2. KPI panel (3 items):**
- The problem: every memory system stores indiscriminately (mem0, MCP Memory, Claude Code auto-memory). Noise drowns signal.
- The solution: scoring layer evaluating reusability, atomicity, novelty, actionability. Below threshold = rejected with reason.
- The proof: 100% accuracy on labeled fixture. 1.0% rejection on 381-item real corpus. Zero false positives on good memories.

**3. Before/after example (bento-grid, 2 wide cards):**
- Left card (REJECTED): a real garbage memory from the fixture with the rejection reason
- Right card (KEPT): a real good memory with the score breakdown

**4. What it does (scan-grid, 3 cards):**
- Scores every candidate on 4 dimensions
- Detects contradictions against existing store
- Prevents feedback loops (recalled memories re-ingested as "new")

**5. Competitive comparison (table):**
| Project | Stars | Quality Gate? |
|---------|-------|--------------|
| mem0 | 56.8k | Hash dedup only (97.8% junk documented) |
| MCP Memory | — | None (9 tools, no filtering) |
| Claude Code | — | LLM judgment (no explicit gate) |
| memory-bank-mcp | 905 | None (raw read/write) |
| **This project** | — | **4-dimension scoring + contradiction + feedback-loop** |

**6. How it works (bento-grid, 4 tall cards):**
- Card 1 (Reusability): would this help in a future session?
- Card 2 (Atomicity): is it one discrete fact?
- Card 3 (Novelty): does the store already know this?
- Card 4 (Actionability): does it change behavior?

**7. Bottom CTA:** "Score your own memory corpus in 60 seconds" → try-it.md

---

### The Gate Page (docs/the-gate.md) — NEW

**1. Hero:** "Four dimensions. One decision. Keep or reject."
**2. Architecture flow:** candidate → extract → score 4 dimensions → threshold check → keep (append) or reject (divert + log reason)
**3. The 4 scoring dimensions** (scan-grid, detailed):
- Reusability (weight, examples of pass/fail)
- Atomicity (weight, examples)
- Novelty (weight, how contradiction detection and feedback-loop work)
- Actionability (weight, examples)
**4. Contradiction detection:** polarity + subject overlap heuristic. Flags when new memory conflicts with existing store entry. `-Store` flag passes store anchors.
**5. Feedback-loop prevention:** blocks recalled memories from being re-extracted. `-Recalled` flag passes session recalls. The mem0 668-copies failure mode this prevents.
**6. Rule catalog summary:** ~40+ rules grouped by junk category (status pings, greetings, self-praise, date-only stamps, etc.)
**7. Integration points:** `--score-one` flag for piping, exit codes (0 keep, 3 reject), log output for dashboard

---

### Evidence Page (docs/evidence.md) — NEW

**1. Hero:** "Numbers, not vibes."
**2. Fixture methodology:**
- 100 items: 50 labeled keep, 50 labeled reject
- Built iteratively over 8 iterations (v1 20 items → v4 100 items)
- Junk categories sourced from mem0 #4573 documented patterns + real-world observations
**3. Results summary:**
- Current: 100% accuracy, 100% good-recall, 100% junk-recall on v4
- Iteration history table showing progressive improvement
**4. Real-corpus validation:**
- 381 items extracted from actual .md memory files
- 1.0% rejection (4 items), all defensible
- Zero false positives on good memories
**5. Before/after examples (3 rejections, 3 keeps):**
- Show the text, the score, the reason
**6. Cross-language parity:**
- Same rules in score-memory.ps1 and score_memory.py
- CI parity check enforces identical per-item decisions
**7. Honest limitations:**
- Polarity+subject heuristic (not embedding-based — paraphrased contradictions may slip through)
- Threshold is conservative (favors keeping over rejecting when borderline)
- No temporal/staleness scoring yet

---

### Try It Page (docs/try-it.md) — NEW

**1. Hero:** "Score your memory corpus in 60 seconds."
**2. Prerequisites:** Python 3.8+ or PowerShell 7+, git
**3. Quick start (3 commands):**
```bash
git clone https://github.com/victorfelisbino/my-agent-memory.git
cd my-agent-memory/admission-gate
echo '{"text":"Always use try-catch in JavaScript"}' | python3 score_memory.py --score-one
# → {"decision":"keep","score":2.8,...}
```
**4. Score your own corpus:**
- Point extract-corpus.ps1 at your .md files
- Or format your memories as JSONL (one {"text":"..."} per line)
- Run the full scorer with -FailUnder to set your bar
**5. Integrate into your pipeline:**
- Exit code 0 = keep, exit code 3 = reject
- `--log-to scoring.jsonl` for audit trail
- `--store store.jsonl` for contradiction detection
- `--recalled session.jsonl` for feedback-loop prevention
**6. Bonus: anti-hallucination skill:**
- Copy-paste into your agent config for immediate value while the gate filters writes

---

### Background Tab — REGROUP EXISTING

Minor edits to `framework-purpose.md`:
- Reframe from "what it does" to "why we built this" — the origin story
- Keep the content largely intact but update the hero headline from "Capture lessons..." to "Why this exists: the origin story"

All other pages under Background remain unchanged in content, just moved in nav position.

---

## mkdocs.yml Changes

```yaml
nav:
  - Home: index.md
  - The Gate:
      - How it works: the-gate.md
      - Evidence: evidence.md
  - Try It: try-it.md
  - Background:
      - Origin story: framework-purpose.md
      - Two-repo pattern: framework-scope.md
      - Memory adoption playbook: memory-adoption-playbook.md
      - Principles: principles-ways-of-thinking.md
      - Copilot auto-mode: copilot-auto-mode.md
      - Quick restart routine: quick-restart-routine.md
      - Anti-hallucination skill: anti-hallucination-skill.md
  - Status & Direction:
      - Status (what's real today): status.md
      - Roadmap: roadmap.md
      - Competence map: competence-map.md
      - Competitive landscape (May 2026): competitive-landscape-2026-05.md
      - Memory ecosystem research: memory-ecosystem-research-2026-05-15.md
```

`site_description` updated to: "The quality gate for AI agent memory. Scores candidates on reusability, atomicity, novelty, and actionability — rejects the garbage before it reaches storage."

---

## CSS Changes

None. The existing design system (landing-shell, kpi-panel, bento-grid, scan-grid, pills, CTAs) covers everything needed.

---

## Files Modified

1. `docs/index.md` — full rewrite
2. `docs/framework-purpose.md` — minor reframe (hero text only)
3. `mkdocs.yml` — nav restructure + site_description update

## Files Created

4. `docs/the-gate.md` — new page
5. `docs/evidence.md` — new page
6. `docs/try-it.md` — new page

## Files Removed from Nav (kept on disk)

7. `docs/should-you-use-this.md` — no longer in nav (content absorbed elsewhere)

---

## Implementation Notes

- Pull real fixture examples for before/after cards from `admission-gate/fixtures/memories-v4.jsonl`
- Pull iteration history from roadmap Wave 3 section
- Verify `score_memory.py --score-one` actually works with stdin JSON pipe (test before documenting)
- Run `mkdocs build --strict` after changes to catch broken internal links
