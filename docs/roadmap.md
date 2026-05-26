# Roadmap

**Destination:** A guardrail-aware memory layer for coding agents — the thing that sits between an IDE agent (Copilot, Cline, Cursor) and a production-grade fact store (mem0, OpenMemory), and adds the pieces nobody else has: transfer-tested promotion, anti-hallucination injection, and router hints.

**Honest starting point (May 2026):** A documented set of patterns and a working two-repo split. The unique ideas — transfer-test, anti-hallucination injection, router hints — are written down but not end-to-end shipped. The framework label is aspirational. Eight competing projects exist; none own this niche.

This roadmap moves in waves. Each wave has a single goal, a cheap exit criterion, and a "kill switch" — what tells us to stop and pivot instead of grinding.

---

## Wave 0 — Honesty pass (1-2 weeks, ~8h) &mdash; **IN PROGRESS**

**Goal:** Stop claiming things that aren't true. Make the repo match reality before inviting anyone in.

**Done:**
- Stripped "operating system" / unconditional "framework" language from `docs/framework-scope.md` and `README.md`. The word *framework* is now explicitly aspirational until Wave 4 earns it back.
- Fixed the false "anti-hallucination is auto-injected" claim in `docs/copilot-auto-mode.md` and `docs/should-you-use-this.md`.
- Removed the misleading Release badge from README (no releases exist).
- Marked `team-memory/`, `team-memory/canonical/`, and `team-memory/inbox/` READMEs as aspirational and empty.
- Added [`docs/status.md`](status.md) as the single source of truth for what's real vs documented vs planned.
- Added this roadmap to the published site nav.

**Still to do:**
- Decide on `goals.md`: it's listed as private and gitignored (correct), and references in `README.md` and `weekly-review-checklist.md` describe it as a file in the *personal* repo (consistent). No contradiction; leave as-is.
- Optional: rename `team-memory/canonical/` &rarr; `team-memory/proposed/` or delete the empty folder entirely. Currently kept and labeled aspirational.

**Exit criterion:** A stranger reading the repo can't be misled about what works. ([`status.md`](status.md) is the test.)

**Kill switch:** None. This wave always ships.

---

## Wave 1 — Make one unique thing actually work (3-4 weeks, ~20h) &mdash; **IN PROGRESS**

**Goal:** Pick the smallest of the three "unique ideas" and ship it end-to-end so we have one real differentiator instead of three aspirational ones.

**Pick:** Anti-hallucination protocol injection. It's the smallest, the most defensible, and the one that maps cleanest onto an existing extension point (VS Code agent skills).

**Done:**
- Packaged `anti-hallucination-protocol.md` into a reusable skill at [`skills/general/anti-hallucination/skill.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/skill.md) with front-matter and a copy-paste block.
- Wrote per-agent install paths in [`install.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/install.md) (Copilot custom instructions, Cline `.clinerules`, Cursor `.cursorrules`, manual one-off).
- Wrote the five-prompt before/after test harness in [`test-prompts.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/test-prompts.md) with binary pass/fail rules.
- Wrote [`results-template.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/results-template.md) for recording runs.
- Added [Anti-hallucination skill](anti-hallucination-skill.md) page to the published site.

**Still to do:**
- Actually run the five-prompt harness against at least one agent (Copilot Chat) in this workspace, record results, publish a redacted version under `skills/general/anti-hallucination/results-examples/`.
- Sharpen the skill text based on what the harness exposes.

**Exit criterion:** A reproducible demo where the same prompt gets a measurably better answer with the skill loaded than without. Target: 3 of 5 prompts pass with skill loaded and fail without it.

**Kill switch:** If after running the harness no measurable behavior change shows up, the protocol is vibes — go back to Wave 0 and rewrite it or remove it.

---

## Wave 2 — Public probe (2-3 weeks, ~15-20h) &mdash; **IN PROGRESS**

**Goal:** Get one real external data point before investing another 50+ hours. Cheapest credible probe wins.

**Do:** Open a PR contributing the Wave 1 anti-hallucination skill to [`groupzer0/vs-code-agents`](https://github.com/groupzer0/vs-code-agents). They have a first-class skills system, an active maintainer, and explicitly invite contributions. 268 stars = small enough that a real PR gets attention, large enough that signal is meaningful.

**Done:**
- PR opened: [groupzer0/vs-code-agents#10](https://github.com/groupzer0/vs-code-agents/pull/10) — adds `vs-code-agents/skills/anti-hallucination/SKILL.md` matching their existing skill convention, with a per-agent usage table (Planner / Architect / Implementer / Critic / Code-Reviewer / Security / QA / UAT / DevOps).

**Still to do:**
- Watch for review / reaction. Clock starts on the PR-open date.
- Optionally post a recorded harness run against one of their agents in the PR thread if maintainers ask for evidence.

**Track:**
- Was the PR reviewed within 2 weeks?
- Was it merged, requested changes, or ignored?
- Did anyone outside the maintainer comment, star, or fork because of it?
- Did any issue/discussion reference the transfer-test or router-hints ideas?

**Exit criterion:** A clear signal (merged + engagement, merged + silence, rejected, or ignored) within 4 weeks.

**Kill switch:** If the PR is rejected on grounds that invalidate the concept (not just style), the anti-hallucination idea may not generalize. Reconsider before Wave 4.

---

## Wave 3 — Decision gate (1 day, ~2h)

**Goal:** Read the Wave 2 signal and pick exactly one of three paths. No drift, no "both."

**Read the signal:**

| Wave 2 outcome | Path |
|---|---|
| Merged + outside engagement | **Path A: Pivot.** Build the layer-on-mem0 architecture (Wave 4). |
| Merged + silence, or "interesting but not for us" | **Path B: Contribute & integrate.** Stay solo, but ship 2-3 more upstream PRs to other projects (Wave 4-alt). |
| Rejected on concept, or zero response after 4 weeks | **Path C: Archive gracefully.** Write the lessons-learned essay, sunset the repo, move on. |

**Exit criterion:** A one-line decision committed to `STATUS.md`. No reopening for 90 days.

---

## Wave 4 (Path A) — Pivot to "Copilot Guardrail Layer" (6-10 weeks, ~40-60h)

**Goal:** Stop reinventing storage. Become the opinionated guardrail layer on top of someone else's fact store.

**Do:**
- Rebrand the repo: `my-agent-memory` → "Copilot Guardrail Layer" (or similar). New README, new positioning.
- Architecture: mem0 (or OpenMemory) as backing store; thin Python/TS layer adds promotion gates, anti-hallucination injection, router-hint headers.
- Ship as an MCP server so any IDE agent that speaks MCP (Cline, Cursor, Claude Desktop) can use it.
- Keep the unique IP: transfer-test promotion, router hints, anti-hallucination injection.
- Drop the team-memory / canonical / inbox structure entirely — that was a different product.

**Exit criterion:** A working MCP server that a Cline or Copilot user can install in <5 minutes and see facts + guardrails injected into their next prompt.

**Kill switch:** If after 40h the MCP integration still doesn't work end-to-end, the abstraction is wrong. Stop, reassess, consider Path B instead.

## Wave 4 (Path B) — Contribute & integrate (6-10 weeks, ~40-60h)

**Goal:** No pivot. Stay a personal toolkit, but get the unique ideas adopted by projects that already have reach.

**Do:**
- PR `memory_search` (BM25 or embeddings) into [`alioshr/memory-bank-mcp`](https://github.com/alioshr/memory-bank-mcp) — clean MCP transport gap, small TS codebase.
- PR a `guardrail_sector` proposal into OpenMemory's multi-sector model (they're in rewrite, welcoming PRs).
- Write up the transfer-test promotion concept as a public essay; submit to one or two AI/LLM newsletters.
- Keep `my-agent-memory` as the personal reference implementation. Update `STATUS.md` to say exactly that.

**Exit criterion:** At least one upstream PR merged or in active review; one external essay published.

**Kill switch:** If both PRs are rejected/ignored, fall back to Path C.

## Wave 4 (Path C) — Archive (1-2 weeks, ~10h)

**Goal:** Exit cleanly. No vapor-roadmap left sitting in `main`.

**Do:**
- Write one public post-mortem: what worked, what didn't, what the landscape taught us.
- Move the best patterns into a single short reference doc.
- Archive the repo on GitHub. Pin the post-mortem.
- Continue using mem0 / Cline / vs-code-agents personally.

**Exit criterion:** Repo archived, post-mortem live, no maintenance burden.

---

## Wave 5 (Path A only) — Differentiation moat (3-6 months, ~80-120h)

**Goal:** Build the things competitors can't easily copy.

**Do:**
- **Transfer-test harness.** Given a lesson, automatically test whether it applies in N synthetic domains (a new language, a new framework, a new problem class). Score it. Only promote if the score crosses a threshold. This is the academic-paper-grade differentiator.
- **Router-hints loop.** Inject `<!-- task: X | complexity: Y | suggest-model: Z -->` headers; measure whether Copilot's model choice changes; publish the data.
- **Promotion telemetry.** Track which promoted lessons actually get retrieved later. Prune the ones that don't. This is the loop nobody else closes.
- **Public benchmarks.** A small reproducible benchmark suite showing the guardrail layer changes outcomes on real coding tasks.

**Exit criterion:** Two of the four shipped with public measurements.

**Kill switch:** If after 80h no measurement shows the layer matters, the thesis is wrong. Pivot to Path B or Path C.

---

## Wave 6 (Path A only) — Community & sustainability (ongoing)

**Goal:** Stop being a one-person repo.

**Do:**
- Real CONTRIBUTING.md, real PR template, real CHANGELOG, real release cadence.
- A working CI that runs the benchmark suite, not just `bash -n` and PowerShell parse checks.
- A public roadmap board on GitHub Projects (this file moves there).
- Office hours / Discord / whatever the niche actually uses.
- An invitation to one or two outside contributors who showed up in Wave 2 or Wave 5.

**Exit criterion:** At least one merged PR from a contributor who isn't the original author.

**Kill switch:** If after 6 months there's no outside contributor and no usage signal, downgrade to "maintained personal project" — don't keep performing framework theater.

---

## What this roadmap deliberately does not promise

- A SaaS product. mem0 / Zep / Letta already won that lane; competing requires money this project doesn't have.
- A team-memory workflow. The `team-memory/` folders are empty and nobody asked for them. They get deleted in Wave 4-A.
- A general-purpose LLM memory framework. The niche is *coding agents with guardrails* — stay in lane.
- A timeline in calendar weeks. Effort estimates are ranges; calendar dates aren't.

## The honest summary

Five paths converge to two real questions:

1. **Does anyone outside this repo care about anti-hallucination injection as a reusable skill?** (Wave 2 answers this for ~20h of work.)
2. **If yes, can the guardrail layer be built on top of mem0 instead of replacing it?** (Wave 4-A answers this for ~50h.)

If the answer to both is yes, this becomes a real project with a defensible niche. If either is no, the right move is to contribute the good ideas upstream and stop running a solo framework.
