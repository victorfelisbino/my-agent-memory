# Status

**As of:** May 26, 2026

This page exists so the public-facing claims in the rest of the docs can't drift. If a feature is described as working anywhere on the site, it should appear in the **Real today** column below. If it doesn't, the docs are wrong and need fixing.

Three columns:

- **Real today** &mdash; ships end-to-end, runs on my machine right now, can be reproduced from this repo.
- **Documented only** &mdash; the pattern is written down, sometimes with example scripts, but it's not wired into a one-command path you can rely on. Treat as a design sketch.
- **Planned** &mdash; called out in the [roadmap](roadmap.md), not started.

## Real today

- **Two-repo split.** Framework lives here; private state lives in a sibling `my-agent-memory-personal` repo. Path resolution via `AGENT_MEMORY_PERSONAL`, sibling directory, or fallback.
- **Cross-machine sync.** `sync-memory.ps1` / `.sh` pulls, captures from local Copilot transcripts, regenerates `active-threads.md`, optionally commits + pushes the personal repo. `.gitattributes` merge=union prevents conflicts on `observations.jsonl`.
- **One-verb capture.** `loop.ps1` / `.sh` with `idea | start | promise | wait | done | show`. Every capture also appends to `observations.jsonl`.
- **Context brief generation.** `summon-memory.ps1` produces a ranked brief (full or `-Compact`) with a router-hints header for Copilot auto-mode.
- **Weekly synthesis loop.** `run-weekly-memory.ps1` runs the learner, captures, synthesizes, lints team-memory, and commits.
- **Daily scheduled task install (Windows).** `install-scheduled-task.ps1` registers the daily sync.
- **Documented principles, gotchas, and domain playbooks** &mdash; `thinking-principles.md`, `decision-framework.md`, `cognitive-bias-checks.md`, `gotchas.md`, `salesforce-debugging.md`, `domains/`. These are the things `summon-memory` ranks and pulls from.
- **Anti-hallucination skill (load-it-yourself).** Packaged from `anti-hallucination-protocol.md` into [`skills/general/anti-hallucination/`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/) with copy-paste block, per-agent install paths (Copilot / Cline / Cursor), a five-prompt before/after test harness, a results template, and a redacted [example results file](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/results-examples/example-redacted.md). See [Anti-hallucination skill](anti-hallucination-skill.md). Effectiveness in any specific setup still requires running the harness; real-run results across agents not yet aggregated.
- **Public probe.** Anti-hallucination skill submitted upstream to [`groupzer0/vs-code-agents` PR #10](https://github.com/groupzer0/vs-code-agents/pull/10), open and awaiting review (Wave 2). Outcome is the real signal; PR being open is just the probe being live.
- **Competence map.** [`competence-map.yml`](https://github.com/victorfelisbino/my-agent-memory/blob/main/competence-map.yml) at the repo root + [`scripts/generate-competence-map.ps1`](https://github.com/victorfelisbino/my-agent-memory/blob/main/scripts/generate-competence-map.ps1) generator + [Competence map](competence-map.md) page. Depth is author-set; the generator refuses to render `expert` claims without backing evidence and downgrades anything untouched for 90+ days to dormant. Eight shared-scope entries seeded. CI drift-check job rejects PRs that change the YAML without regenerating the page; weekly script regenerates on every run. Two-repo merge with the sibling personal repo + Actions cron are roadmap follow-ups.
- **Admission-gate measurement harness (Wave 3, v3 fixture + 6 iterations).** [`admission-gate/`](https://github.com/victorfelisbino/my-agent-memory/blob/main/admission-gate/) holds a 60-item labeled fixture, a corpus extractor that pulls real bullets from this repo's own .md files, and a baseline stub scorer across the four Wave 3 dimensions with both labeled-accuracy and unlabeled-distribution modes. Current baseline on the v3 fixture: **100% accuracy, 100% good-recall, 100% junk-recall** with zero documented misses (raw run of the iter-5 ruleset against v3 was 90/100/80; iter 6 closed the six new miss shapes with rules for heading-only extraction artifacts, bare placeholder words, aspirational vague wishes, vague comparisons, apology / meta-conversation, and open-question shape). This is still not the Wave 3 exit criterion (>=100 items required) -- the next loop is fixture growth v3 -> v4, not chasing a higher percentage. CI runs the scorer on every PR with `-FailUnder 95` and also smoke-extracts the live real-memory corpus (~403 items); real-corpus rejection went from 0% to 5.5%, and every newly rejected bullet is a true heading-extraction artifact (`Required secrets/variables:`, `Expected output or state:`, ...) that should not have been ingested as memory in the first place. The new heading-only rule surfaced a real extractor bug; the extractor fix is the next iter-7 task. No write-path integration, no dashboard, no novelty lookup yet.
- **CI hardening.** Three jobs: recursive `*.ps1`/`*.sh` parse, `mkdocs build --strict`, competence-map drift check, admission-gate harness run. All required to pass before merge in practice (branch-protection wiring is admin-bypass for now).
- **mkdocs site.** Builds clean with `--strict`, deploys via GitHub Pages workflow.

## Documented only (NOT yet shipped end-to-end)

- **Auto-injected anti-hallucination protocol.** The skill itself now ships as load-it-yourself (see Real today). Auto-injection by `summon-memory` is still not implemented; that's [roadmap](roadmap.md) Wave 4-A territory (MCP server).
- **Transfer-test promotion gate.** The rule ("only promote if it would still apply in a language you haven't met yet") is written into [framework-scope.md](framework-scope.md) and the [memory adoption playbook](memory-adoption-playbook.md). There is no test harness that automates or verifies the gate &mdash; promotion is a manual judgement call today.
- **Router-hints loop.** `summon-memory` emits the header. There is no measurement loop that confirms Copilot's auto-router actually changes its model choice because of it. The numbers in [copilot-auto-mode.md](copilot-auto-mode.md) are observations, not benchmarks.
- **Team-memory workflow.** `team-memory/inbox/` and `team-memory/canonical/` are empty. Approval gates are written down but no lesson has ever flowed through them. Single contributor today.
- **Cross-platform parity.** PowerShell scripts are the daily-driven path. The `.sh` counterparts exist but are less exercised. `install-scheduled-task.ps1` is Windows-only; no `cron` or `launchd` equivalent ships.
- **Skills and connectors layer.** `skills/` and `connectors/` contain templates and one Salesforce example. No agent integration consumes them in a reproducible way.

## Planned (see [roadmap](roadmap.md))

- Run the anti-hallucination test harness on real workflows and publish first-party results (Wave 1 exit criterion).
- Read the signal from [`groupzer0/vs-code-agents` PR #10](https://github.com/groupzer0/vs-code-agents/pull/10) (Wave 2 exit).
- PR quality-gate middleware to `memory-bank-mcp` (Wave 2, Probe B — after Wave 3 prototype exists).
- **Memory admission gate — production scoring + write-path integration + dashboard.** Harness is real today (see Real today); the production gate (scoring rules that hit the 80%+ bar on a 100-item fixture, the local web UI, contradiction detection, novelty lookup, feedback-loop prevention) is Wave 3 still.
- Decision gate: pivot, contribute & integrate, or archive (Wave 4).
- **MCP quality-gate server** wrapping the official MCP Memory server with admission scoring, contradiction detection, staleness decay, anti-hallucination injection, and competence-aware retrieval. Copilot-native path via hook/extension (Wave 5-A).
- Upstream PRs to `memory-bank-mcp` and mem0 (#4573 quality gate) if signal is mixed (Wave 5-B).
- Transfer-test harness, LoCoMo/BEAM benchmarks, promotion telemetry, competence map v2, Claude Code hook integration, public benchmarks (Wave 6).
- Real CONTRIBUTING / CHANGELOG / release cadence / outside contributor (Wave 7).

## Things the docs deliberately do NOT claim

- That this is a framework. The word is reserved for Wave 5 onward.
- That it has users beyond me.
- That the token-savings numbers in [copilot-auto-mode.md](copilot-auto-mode.md) are measured benchmarks. They're observed ranges with a documented measurement protocol you can run yourself.
- That `team-memory/canonical/` is canonical anything. It's an empty folder with an aspirational name.
- That the quality gate exists today. It's designed and the scoring criteria are defined, but no code implements it yet. That's Wave 3.
- That we compete with mem0 / Letta / Zep on storage. We don't store memories — we filter them.

If you find a claim on the site that contradicts this page, the site is wrong. Open an issue.
