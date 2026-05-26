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
- **Anti-hallucination skill (load-it-yourself).** Packaged from `anti-hallucination-protocol.md` into [`skills/general/anti-hallucination/`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/) with copy-paste block, per-agent install paths (Copilot / Cline / Cursor), a five-prompt before/after test harness, and a results template. See [Anti-hallucination skill](anti-hallucination-skill.md). Effectiveness in any specific setup still requires running the harness; results across agents not yet aggregated.
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
- Public probe: PR the anti-hallucination skill into [`groupzer0/vs-code-agents`](https://github.com/groupzer0/vs-code-agents) (Wave 2).
- Decision gate: pivot, contribute & integrate, or archive (Wave 3).
- "Copilot Guardrail Layer" on top of mem0 / OpenMemory as MCP server, if signal is good (Wave 4-A).
- Upstream PRs to `memory-bank-mcp` and OpenMemory if signal is mixed (Wave 4-B).
- Transfer-test harness, router-hints measurement loop, promotion telemetry, public benchmarks (Wave 5).
- Real CONTRIBUTING / CHANGELOG / release cadence / outside contributor (Wave 6).

## Things the docs deliberately do NOT claim

- That this is a framework. The word is reserved for Wave 4 onward.
- That it has users beyond me.
- That the token-savings numbers in [copilot-auto-mode.md](copilot-auto-mode.md) are measured benchmarks. They're observed ranges with a documented measurement protocol you can run yourself.
- That `team-memory/canonical/` is canonical anything. It's an empty folder with an aspirational name.

If you find a claim on the site that contradicts this page, the site is wrong. Open an issue.
