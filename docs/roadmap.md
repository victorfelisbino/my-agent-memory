# Roadmap

**Destination:** The quality gate for AI agent memory. Not another storage layer — the opinionated filter that sits between a coding agent (Copilot, Cline, Cursor, Claude Code) and a fact store (mem0, MCP Memory Server, memory-bank-mcp), and prevents 97% of what gets stored from being garbage. Plus a **shareable competence map** so a brain can advertise what it actually knows, how deep, and with what evidence.

**The market signal (May 2026):** mem0 has 56.8k stars and a [documented 97.8% junk rate](https://github.com/mem0ai/mem0/issues/4573) in production. The official MCP Memory server has no quality gate at all — hash dedup only. Claude Code's auto-memory relies entirely on LLM judgment. Every memory system stores indiscriminately; none say "no." That's our niche.

**What we uniquely ship (or will ship):**
1. **Anti-hallucination injection** — a testable, agent-agnostic skill that prevents the four most common hallucination shapes. Shipped (Wave 1).
2. **Competence map** — a machine-readable inventory of what this brain knows, at what depth, with evidence. Honesty-enforced: the generator refuses to render claims without backing. Building (Wave 2.5).
3. **Memory admission gate** — a scoring layer that rejects low-value memories before they reach storage. Planned (Wave 3).
4. **Transfer-test promotion** — a lesson only gets promoted if it generalizes beyond one language/context. Designed, not automated yet.
5. **Contradiction detection** — flag when a new memory conflicts with an existing one instead of silently storing both.
6. **Feedback loop prevention** — stop recalled memories from being re-extracted as "new" observations.
7. **Staleness decay** — time-based confidence degradation without re-verification.

**Honest starting point:** A working two-repo split, one shipped skill, one live upstream PR, and a set of patterns. The admission gate is designed but not coded. The MCP server doesn't exist yet. We're earlier than Tensory (which already has an MCP server with salience scoring) but have a clearer thesis than anyone about what "quality" means for agent memory.

This roadmap moves in waves. Each wave has a single goal, a cheap exit criterion, and a "kill switch" — what tells us to stop and pivot instead of grinding.

---

## Competitive landscape (as of May 2026)

| Project | Stars | Quality Gate | MCP? | Weakness we exploit |
|---------|-------|-------------|------|---------------------|
| mem0 | 56.8k | Hash dedup only (97.8% junk) | No | No admission filter; stores everything |
| Letta (MemGPT) | 23k | None | No | Agent framework, not a quality layer |
| Zep | 4.6k | Temporal validity (valid_at/invalid_at) | Yes | Cloud-first, deprecated OSS community edition |
| Official MCP Memory | — | None (9 tools, minimal) | Yes | Unopinionated; no scoring or promotion |
| memory-bank-mcp | 905 | None (raw read/write) | Yes | File dump; no curation |
| Tensory | 4 | Salience scoring + collision detection | Yes | Alpha, tiny community, no adoption yet |
| Claude Code auto-memory | — | LLM judgment + 200-line cap | Native | No explicit gate; relies on model quality |
| Copilot instructions | — | None (static files) | No | No learning, no memory, purely declarative |

Full analysis: [docs/competitive-landscape-2026-05.md](competitive-landscape-2026-05.md)

---

## Wave 0 — Honesty pass (1-2 weeks, ~8h) &mdash; **DONE**

**Goal:** Stop claiming things that aren't true. Make the repo match reality before inviting anyone in.

**Done:**
- Stripped "operating system" / unconditional "framework" language from `docs/framework-scope.md` and `README.md`. The word *framework* is now explicitly aspirational until Wave 4 earns it back.
- Fixed the false "anti-hallucination is auto-injected" claim in `docs/copilot-auto-mode.md` and `docs/should-you-use-this.md`.
- Removed the misleading Release badge from README (no releases exist).
- Marked `team-memory/`, `team-memory/canonical/`, and `team-memory/inbox/` READMEs as aspirational and empty.
- Added [`docs/status.md`](status.md) as the single source of truth for what's real vs documented vs planned.
- Added this roadmap to the published site nav.
- Decided on `goals.md`: no contradiction found — correctly listed as private/gitignored, and references in `README.md` and `weekly-review-checklist.md` consistently describe it as a personal-repo file. Left as-is.
- Decided on `team-memory/canonical/`: kept as-is. Already labeled aspirational in `team-memory/README.md`; Wave 4-A would drop the structure entirely anyway.

**Exit criterion:** A stranger reading the repo can't be misled about what works. ([`status.md`](status.md) is the test.)

**Kill switch:** None. This wave always ships.

---

## Wave 1 — Make one unique thing actually work (3-4 weeks, ~20h) &mdash; **DONE**

**Goal:** Pick the smallest of the three "unique ideas" and ship it end-to-end so we have one real differentiator instead of three aspirational ones.

**Pick:** Anti-hallucination protocol injection. It's the smallest, the most defensible, and the one that maps cleanest onto an existing extension point (VS Code agent skills).

**Done:**
- Packaged `anti-hallucination-protocol.md` into a reusable skill at [`skills/general/anti-hallucination/skill.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/skill.md) with front-matter and a copy-paste block.
- Wrote per-agent install paths in [`install.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/install.md) (Copilot custom instructions, Cline `.clinerules`, Cursor `.cursorrules`, manual one-off).
- Wrote the five-prompt before/after test harness in [`test-prompts.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/test-prompts.md) with binary pass/fail rules.
- Wrote [`results-template.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/results-template.md) for recording runs.
- Added [Anti-hallucination skill](anti-hallucination-skill.md) page to the published site.
- Ran the harness against Copilot Chat (GPT-4.1, auto-mode): **5/5 pass.** All five baseline responses showed typical hallucination patterns; all five treatment responses refused to invent, flagged missing context, or listed verification steps. Published redacted results at [`results-examples/example-redacted.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/results-examples/example-redacted.md).

**Exit criterion met:** 5 of 5 prompts pass with skill loaded (target was 3 of 5). The protocol is not vibes — it measurably changes agent behavior on all four hallucination shapes.

---

## Wave 2 — Public probe (2-3 weeks, ~15-20h) &mdash; **IN PROGRESS**

**Goal:** Get real external data points before investing another 50+ hours. Two probes for redundancy.

**Probe A (live):** PR contributing the Wave 1 anti-hallucination skill to [`groupzer0/vs-code-agents`](https://github.com/groupzer0/vs-code-agents) (268 stars, Claude Skills system, explicitly invites contributions). Risk: last activity January 2026, single contributor, depends on Flowbaby.

**Done:**
- PR opened: [groupzer0/vs-code-agents#10](https://github.com/groupzer0/vs-code-agents/pull/10) — adds `vs-code-agents/skills/anti-hallucination/SKILL.md` matching their existing skill convention, with a per-agent usage table.

**Probe B (planned):** PR adding quality-gate middleware to [`alioshr/memory-bank-mcp`](https://github.com/alioshr/memory-bank-mcp) (905 stars, TypeScript, MIT, actively maintained). This is a better audience for the admission-gate concept and has a larger, more active community.

**Still to do:**
- Watch for Probe A review / reaction. Clock starts on PR-open date.
- Ship Probe B once the admission gate from Wave 3 has a working prototype.
- Optionally post a recorded harness run in the PR thread if maintainers ask for evidence.

**Track (both):**
- Was the PR reviewed within 2 weeks?
- Was it merged, requested changes, or ignored?
- Did anyone outside the maintainer engage (comment, star, fork)?
- Did discussion reference quality gates, anti-hallucination, or memory curation?

**Exit criterion:** A clear signal from at least one probe within 4 weeks.

**Kill switch:** If both PRs are rejected on concept (not style), the ideas may not generalize. Reconsider before Wave 4.

---

## Wave 2.5 — Competence map (runs in parallel with Wave 2, ~10-15h) &mdash; **IN PROGRESS**

**Goal:** Make the brain *legible*. Anyone — a teammate, a fork, a future agent loading this memory — should be able to read one page and know what this brain claims to know, how deep, what evidence backs the depth, and whether the knowledge is shareable or personal.

**Why now:** The pitch "transferable semantic layer of a two-repo brain" is not real until the brain can publish a capability inventory. Storing notes is table stakes; advertising competence is the differentiator. This also turns the public repo from "a memory framework" into "a brain you can fork that arrives knowing things," which is a much sharper invitation. It can ship during the 4-week Wave 2 watching window without depending on the probe outcome.

**Done:**

- Defined `competence-map.yml` schema at repo root with seven shared-scope entries: anti-hallucination (working), AI memory architecture (working), thinking principles (working), Salesforce (working), Mulesoft (explore), code review (explore), memory operations (working).
- Shipped [`scripts/generate-competence-map.ps1`](https://github.com/victorfelisbino/my-agent-memory/blob/main/scripts/generate-competence-map.ps1) with embedded minimal YAML parser (no module install required), evidence computation (file count, total bytes, `## ` headings, `gotcha:` / `lesson:` markers, last git touch), and honesty enforcement (non-zero exit on missing source paths, `expert` with no evidence, `expert` untouched 180+ days). Auto-downgrades anything untouched 90+ days to `dormant` in the rendered view.
- Shipped `scripts/generate-competence-map.sh` parity stub that delegates to `pwsh` when present.
- Banned-name lint reads `$env:COMPETENCE_MAP_BANNED_NAMES` (comma-separated) and fails the build if any appear in the YAML.
- Generated [Competence map](competence-map.md), grouped by tier, with totals header strip and `Generated:` timestamp.
- Added nav entry under "What this brain knows." Linked from `docs/status.md` (now in `Real today`).

**Still to do:**

- Two-repo merge: `--include-personal` flag reads the sibling `my-agent-memory-personal/competence-map.yml` and produces a local-only `competence-map-full.md` that mixes shared + personal entries. The published site still shows the shared-only view.
- Wire into `run-weekly-memory.ps1` so the map regenerates as part of the weekly loop.
- GitHub Actions cron that regenerates the map daily and commits if anything changed.
- README pointer.

**Exit criterion:** `docs/competence-map.md` is live on the published site, regenerated by script, depth values author-set, evidence values computed. A stranger landing on the page can answer "what does this brain know?" in under 30 seconds. **Met.**

**Kill switch:** If after the first generation the map looks like vanity (every domain marked `expert` with thin evidence), throw it all out and downgrade everything to `explore` until evidence catches up. The honesty bar is the whole point.

---

## Wave 3 — Memory admission gate + dashboard (3-4 weeks, ~20h) &mdash; **IN PROGRESS**

**Goal:** Build the first working version of the quality gate — the thing that says "no" to bad memories — and make the filtering **visible**. This is the #1 unmet need in the ecosystem (mem0 issue #4573 proves it). Pain point #3 is that nobody can see what's stored or why things were rejected.

**Done (measurement harness, v1):**

- [`admission-gate/fixtures/memories-v1.jsonl`](https://github.com/victorfelisbino/my-agent-memory/blob/main/admission-gate/fixtures/memories-v1.jsonl) — 20 labeled memories (10 keep, 10 reject) covering the documented junk categories: boot noise, heartbeat, transient task state, hallucinated profile, vague non-actionable, self-referential, world noise, project-private without portable lesson, tautology, contradiction-in-one-line.
- [`admission-gate/score-memory.ps1`](https://github.com/victorfelisbino/my-agent-memory/blob/main/admission-gate/score-memory.ps1) — baseline scorer across the four spec dimensions (reusability, atomicity, novelty stubbed, actionability). Emits per-memory decision + summary; supports `-FailUnder` for CI gating and `-Unlabeled` for scoring real corpora.
- [`admission-gate/extract-corpus.ps1`](https://github.com/victorfelisbino/my-agent-memory/blob/main/admission-gate/extract-corpus.ps1) — extracts atomic bullets from real .md memory files into a JSONL corpus, so the scorer can be aimed at actual memory and not just the synthetic fixture.
- CI job `admission-gate-harness` runs the scorer on every PR with `-FailUnder 90` AND smoke-extracts + scores the live real-memory corpus (~403 items, 0% rejection).
- Current baseline: **95% accuracy, 100% good-recall, 90% junk-recall** on the v2 fixture (40 items, doubled from v1). Iteration history: v1 75/100/50 -> iter1 80/100/60 -> iter2 95/100/90 (on v1) -> iter3 100/100/100 (on v1, all v1 misses closed) -> iter4 95/100/90 (fixture v1 20 -> v2 40; +6 new rules; threshold tightened to > 0; two documented misses: named-person preference, generic world-noise). The accuracy dip from 100% on v1 to 95% on v2 is the intended signal -- a bigger fixture is exposing real blind spots that a smaller fixture hid. **The Wave 3 exit criterion is still ahead**: it requires the fixture to be >=100 items and the scorer to beat random by >=30 points on it.

**Still to do:**

**Admission gate (core):**
- Implement a scoring function that evaluates a candidate memory on: reusability (does it generalize?), atomicity (one fact, not a dump?), novelty (not already stored?), actionability (would an agent use this?).
- Score threshold: memories below it get rejected with a reason. Above it get stored.
- Feedback loop prevention: if a memory was recalled in the current session, it cannot be re-ingested as a "new" observation.
- Contradiction detection: flag when a new candidate conflicts with an existing stored memory (semantic similarity above threshold + opposing sentiment/claim).
- Ship as a standalone Python/TS module that can be used as middleware in any pipeline.
- Test against a sample of mem0's documented junk categories (boot prompts, heartbeat noise, hallucinated profiles, transient task state).

**Dashboard (visibility layer):**
- Local web UI (lightweight — single HTML + JS, or minimal framework) that shows:
  - **Live scoring feed:** each candidate memory, its scores on each dimension, pass/reject decision, and rejection reason.
  - **Contradiction warnings:** pairs of conflicting memories with similarity scores.
  - **Feedback loop blocks:** memories that were blocked because they were recalled earlier in the session.
  - **Memory health summary:** total stored, total rejected, rejection rate, top rejection reasons, quality score distribution.
  - **Staleness view:** memories approaching decay threshold, sorted by days since last verification.
- Serves from the gate process (or as a CLI command that reads the scoring log).
- No auth required (local-only by default).

**Exit criterion:** Given a sample of 100 memories (50 good, 50 from the documented junk categories), the gate correctly rejects 80%+ of junk while keeping 80%+ of good memories. The dashboard renders the scoring decisions in real time.

**Kill switch:** If the scoring function can't beat random (50/50) on the test set, the quality criteria aren't well-defined enough yet — go back to manual curation. Dashboard ships regardless as an audit tool even if scoring needs rework.

---

## Wave 4 — Decision gate (1 day, ~2h) &mdash; **PLANNED**

**Goal:** Read the Wave 2 + Wave 3 signals and pick exactly one of three paths. No drift, no "both."

**Read the signal:**

| Signal | Path |
|---|---|
| Probe merged + outside engagement AND gate works (80%+ accuracy) | **Path A: Pivot.** Build the MCP quality-gate server (Wave 5). |
| Mixed signals (one probe merged but quiet, or gate works but no outside interest) | **Path B: Contribute & integrate.** Stay solo, ship upstream PRs (Wave 5-alt). |
| Both probes rejected on concept, OR gate can't beat random | **Path C: Archive gracefully.** Write the lessons-learned essay, sunset the repo, move on. |

**Exit criterion:** A one-line decision committed to `STATUS.md`. No reopening for 90 days.

---

## Wave 5 (Path A) — Ship the MCP Quality Gate Server (6-10 weeks, ~40-60h) &mdash; **PLANNED**

**Goal:** Stop reinventing storage. Become the opinionated quality layer on top of someone else's fact store. The thing that says "no" so your memory doesn't become 97.8% garbage.

**Architecture decision:** Build on the **official MCP Memory server** (knowledge graph, JSONL, 9 tools) rather than mem0. Rationale: mem0 has no MCP support, the official server is MIT and minimal, and wrapping it with quality gates is the smallest useful increment.

**Do:**
- Ship as an MCP server (TypeScript or Python) that wraps or extends the MCP reference memory server.
- **Admission gate:** Every `create_entities` / `add_observations` call passes through the scoring function from Wave 3. Below threshold = rejected with reason.
- **Feedback loop prevention:** Track which memories were recalled in the current session; block re-ingestion.
- **Contradiction detection:** Semantic similarity check against existing graph; flag conflicts before storing.
- **Staleness decay:** Each memory gets a `last_verified` timestamp; confidence degrades linearly over time. Memories below a decay threshold get flagged for re-verification or pruned.
- **Anti-hallucination injection:** Automatically inject the protocol into the context when the agent connects.
- **Competence-aware retrieval:** Use the competence map to weight retrieval results — memories from `expert` domains rank higher than `explore` domains.
- **Two injection paths:**
  - MCP-native: Cline, Cursor, Claude Desktop, Claude Code (all speak MCP)
  - Copilot-native: A Claude Code hook or VS Code extension that writes guardrails into `.github/copilot-instructions.md` or `AGENTS.md` dynamically
- **Dashboard v2:** Upgrade the Wave 3 local dashboard to connect to the MCP server. Add: knowledge graph visualization, entity relationship explorer, retrieval hit-rate tracking, competence map overlay showing which domains are being queried most.
- Drop the team-memory / canonical / inbox structure entirely — that was a different product.
- Rebrand positioning: "The quality gate for AI agent memory."

**Exit criterion:** A working MCP server that a Cline or Claude Code user can install in <5 minutes and see: (a) bad memories rejected with reasons, (b) anti-hallucination protocol injected, (c) contradiction warnings on conflicting facts.

**Kill switch:** If after 40h the MCP integration still doesn't work end-to-end, the abstraction is wrong. Consider wrapping memory-bank-mcp instead, or fall back to Path B.

## Wave 5 (Path B) — Contribute & integrate (6-10 weeks, ~40-60h) &mdash; **PLANNED**

**Goal:** No pivot. Stay a personal toolkit, but get the quality-gate ideas adopted by projects that already have reach.

**Do:**
- PR an admission-gate middleware into [`alioshr/memory-bank-mcp`](https://github.com/alioshr/memory-bank-mcp) (905 stars, TS, actively maintained) — adds scoring + rejection to their raw read/write.
- PR a quality-gate proposal into mem0 (directly addressing their [#4573 junk-rate issue](https://github.com/mem0ai/mem0/issues/4573)) — scoring between extraction and storage.
- Write up the transfer-test promotion concept and mem0 quality findings as a public essay; submit to AI/LLM newsletters.
- Keep `my-agent-memory` as the personal reference implementation. Update `STATUS.md` to say exactly that.

**Exit criterion:** At least one upstream PR merged or in active review; one external essay published.

**Kill switch:** If both PRs are rejected/ignored, fall back to Path C.

## Wave 5 (Path C) — Archive (1-2 weeks, ~10h)

**Goal:** Exit cleanly. No vapor-roadmap left sitting in `main`.

**Do:**
- Write one public post-mortem: what worked, what didn't, what the landscape taught us.
- Move the best patterns into a single short reference doc.
- Archive the repo on GitHub. Pin the post-mortem.
- Continue using mem0 / Cline / vs-code-agents personally.

**Exit criterion:** Repo archived, post-mortem live, no maintenance burden.

---

## Wave 6 (Path A only) — Differentiation moat (3-6 months, ~80-120h) &mdash; **PLANNED**

**Goal:** Build the things competitors can't easily copy. Prove with numbers that the quality gate changes outcomes.

**Do:**
- **Transfer-test harness.** Given a lesson, automatically test whether it applies in N synthetic domains (a new language, a new framework, a new problem class). Score it. Only promote if the score crosses a threshold. This is the academic-paper-grade differentiator.
- **LoCoMo / BEAM benchmarks.** Run our quality gate against established memory benchmarks. Tensory scores 82.2% on LoCoMo; mem0 scores 91.6. Publish our numbers. If the gate improves retrieval precision (fewer junk results = better answers), that's the headline.
- **Promotion telemetry.** Track which promoted lessons actually get retrieved later. Prune the ones that don't. This is the loop nobody else closes.
- **Competence map v2.** Inferred depth: use retrieval + capture telemetry to *propose* depth changes (e.g. "`mulesoft` hasn't been retrieved in 120d, downgrade to dormant?"). Hand-confirm before applying. Cross-brain merge so two forks can produce a combined competence inventory.
- **Claude Code hook integration.** Ship as a Claude Code hook (`InstructionsLoaded` or post-memory-write) that runs the quality gate on auto-memory saves. Zero-friction path for Claude Code users without needing a separate MCP server.
- **Public benchmarks.** A reproducible suite showing: (a) junk rejection rate on mem0-style workloads, (b) retrieval precision improvement, (c) before/after hallucination rates on coding tasks.
- **Dashboard v3.** Memory health over time (trend graphs), benchmark result visualization, exportable reports. This is the "show, don't tell" layer for public credibility.

**Deprioritized:** Router-hints loop. Copilot's auto-router doesn't expose whether it reads our headers; unmeasurable = not a differentiator until proven otherwise. Keep as an experiment, not a wave goal.

**Exit criterion:** Two of the six shipped with public measurements.

**Kill switch:** If after 80h no measurement shows the layer matters, the thesis is wrong. Pivot to Path B or Path C.

---

## Wave 7 (Path A only) — Community & sustainability (ongoing) &mdash; **PLANNED**

**Goal:** Stop being a one-person repo.

**Do:**
- Real CONTRIBUTING.md, real PR template, real CHANGELOG, real release cadence.
- A working CI that runs the benchmark suite, not just `bash -n` and PowerShell parse checks.
- A public roadmap board on GitHub Projects (this file moves there).
- Office hours / Discord / whatever the niche actually uses.
- An invitation to one or two outside contributors who showed up in Wave 2 or Wave 6.

**Exit criterion:** At least one merged PR from a contributor who isn't the original author.

**Kill switch:** If after 6 months there's no outside contributor and no usage signal, downgrade to "maintained personal project" — don't keep performing framework theater.

---

## What this roadmap deliberately does not promise

- **A storage layer.** mem0 (56.8k stars), Letta (23k), Zep (4.6k), and the official MCP Memory server already handle storage. We don't compete there.
- **A SaaS product.** Those players already won that lane; competing requires money this project doesn't have.
- **A team-memory workflow.** The `team-memory/` folders are empty and nobody asked for them. They get deleted in Wave 5-A.
- **A general-purpose LLM memory framework.** The niche is *quality gates for coding agent memory* — stay in lane.
- **Router hints as a primary differentiator.** Until Copilot exposes whether it reads model-hint headers, this remains unmeasurable. Experiment, not feature.
- **A timeline in calendar weeks.** Effort estimates are ranges; calendar dates aren't.

## The honest summary

The market has proven two things:

1. **Agent memory storage is a solved problem.** mem0, MCP Memory, memory-bank-mcp — pick one.
2. **Agent memory quality is an unsolved problem.** mem0's 97.8% junk rate, Claude Code's reliance on LLM judgment, everyone else's "store everything" approach. Nobody filters. Nobody says no.

Four questions determine whether this becomes a real project:

1. **Does anyone outside this repo care about anti-hallucination injection as a reusable skill?** (Wave 2 Probe A — live, awaiting signal.)
2. **Can this brain credibly publish what it knows?** (Wave 2.5 answers this for ~10-15h. If the competence map looks honest and useful, the "transferable semantic layer" pitch gets real; if it looks like vanity, the pitch was empty.)
3. **Can we build a quality gate that demonstrably rejects junk while keeping good memories?** (Wave 3 answers this for ~15h.)
4. **Can the quality gate + competence map ship as MCP middleware on top of existing storage?** (Wave 5-A answers this for ~50h.)

If all four are yes, this is "the quality gate for AI agent memory" — a real product with a defensible niche and a forkable brain. If any is no, contribute the ideas upstream and stop.

## Key competitors to watch

- **Tensory** (4 stars, alpha) — closest to our vision. Has salience scoring + MCP today. If they get traction before we ship, our path narrows. Monitor monthly.
- **mem0** (56.8k stars) — if they add a quality gate themselves (responding to #4573), our biggest value prop evaporates. Their new April 2026 algorithm didn't address this. Monitor their changelog.
- **Claude Code auto-memory** — if Anthropic adds quality scoring to auto-memory natively, Claude Code users won't need us. Currently relies on LLM judgment with a 200-line cap. No scoring.
- **Zep / Graphiti** — temporal validity (valid_at/invalid_at) is a form of staleness management. Cloud-first, deprecated OSS. Not direct competition but their ideas inform Wave 5-A's decay mechanism.
