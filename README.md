# my-agent-memory

[![CI](https://img.shields.io/github/actions/workflow/status/victorfelisbino/my-agent-memory/ci.yml?branch=main)](https://github.com/victorfelisbino/my-agent-memory/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**The quality gate for AI agent memory.** Not another storage layer &mdash; the opinionated filter that prevents your agent's memory from becoming 97% garbage.

mem0 (56.8k stars) has a [documented 97.8% junk rate](https://github.com/mem0ai/mem0/issues/4573) in production. The official MCP Memory server stores everything with no filter. Claude Code's auto-memory relies on LLM judgment alone. Every memory system stores indiscriminately. This project builds the part that says **no**.

What this repo solves, in plain language:

1. **Stop storing garbage.** A memory admission gate that scores candidate memories on reusability, atomicity, novelty, and actionability &mdash; and rejects the ones that fail, with a machine-readable reason and exit code.
2. **Stop hallucination feedback loops.** Prevent recalled memories from being re-extracted as "new" observations &mdash; the failure mode that created 668 copies of a single hallucination in mem0.
3. **Catch contradictions at write time.** Polarity + subject-overlap analysis flags candidates that conflict with what's already stored instead of silently creating duplicates.
4. **Advertise what this brain knows.** A competence map that publishes expertise depth with computed evidence &mdash; honest by construction, refuses to render unsubstantiated claims.
5. **Keep durable lessons readable by any agent.** Curated principles, gotchas, and domain playbooks that editor-native memory (Copilot memory scopes, CLAUDE.md, Cursor rules) can point at directly.

> **June 2026 restructure.** This repo used to ship a full capture/sync/summon/weekly pipeline (`loop`, `sync-memory`, `summon-memory`, `run-weekly-memory`, scheduled tasks). Editor-native memory has made that plumbing redundant, so it was retired &mdash; see [docs/status.md](docs/status.md). The repo now focuses on the part nobody else ships: the admission gate, plus the curated knowledge layer and the two-repo privacy pattern as documentation. The retired scripts live in git history if you want them.

What to read first:

- [docs/status.md](docs/status.md) &mdash; what's actually working today vs documented-only vs planned vs retired.
- [docs/roadmap.md](docs/roadmap.md) &mdash; where this is going and the kill switches for each wave.
- [docs/framework-scope.md](docs/framework-scope.md) &mdash; what belongs in this repo and what doesn't.
- [docs/index.md](docs/index.md) &mdash; the published site entry.
- [CONTRIBUTING.md](CONTRIBUTING.md) &mdash; if you want to propose a change.

## Quick start: the admission gate (60 seconds)

The fastest way to test the core product behavior (keep vs reject with a machine-readable exit code):

```bash
git clone https://github.com/victorfelisbino/my-agent-memory.git
cd my-agent-memory/admission-gate

# Expect: keep, exit code 0
echo '{"text":"Always validate input at system boundaries."}' | python3 score_memory.py --score-one

# Expect: reject, exit code 3
echo '{"text":"Session started 2026-05-26 at 09:00 on office-pc."}' | python3 score_memory.py --score-one
```

Windows PowerShell equivalent:

```powershell
git clone https://github.com/victorfelisbino/my-agent-memory.git
cd my-agent-memory\admission-gate

# Expect: keep, exit code 0
echo '{"text":"Always validate input at system boundaries."}' | python score_memory.py --score-one

# Expect: reject, exit code 3
echo '{"text":"Session started 2026-05-26 at 09:00 on office-pc."}' | python score_memory.py --score-one
Write-Output "exit=$LASTEXITCODE"
```

The scorer ships in two languages with CI-enforced parity: [admission-gate/score_memory.py](admission-gate/score_memory.py) (embeddable as middleware anywhere) and [admission-gate/score-memory.ps1](admission-gate/score-memory.ps1). See [admission-gate/README.md](admission-gate/README.md) for fixtures, the measurement harness, store/recalled checks, and the local dashboard.

## Wire it into your own pipeline

The scorer is designed to sit between your capture step and your storage:

```bash
#!/bin/bash
MEMORY_TEXT="$1"
RESULT=$(echo "{\"text\":\"$MEMORY_TEXT\"}" | python3 score_memory.py --score-one)
if [ $? -eq 0 ]; then
    echo "$MEMORY_TEXT" >> observations.jsonl
else
    echo "Rejected: $(echo "$RESULT" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("reason",""))')"
fi
```

Add `--store your-store.jsonl` for contradiction detection against existing memories, and `--recalled session.jsonl` to block feedback loops (recalled memories re-ingested as "new").

## What else lives here

### Knowledge layer — *curated, durable lessons*

Markdown files any agent can read directly (point your Copilot instructions, CLAUDE.md, or Cursor rules at them):

- [anti-hallucination-protocol.md](anti-hallucination-protocol.md), [thinking-principles.md](thinking-principles.md), [decision-framework.md](decision-framework.md), [cognitive-bias-checks.md](cognitive-bias-checks.md), [exploration-modes.md](exploration-modes.md) — how to reason.
- [gotchas.md](gotchas.md), [salesforce-debugging.md](salesforce-debugging.md), [project-commands.md](project-commands.md) — curated practices and commands.
- [domains/](domains/) — domain-specific playbooks.
- [lesson-template.md](lesson-template.md) — the capture standard for new lessons.

### Skills layer

- [skills/general/anti-hallucination/](skills/general/anti-hallucination/) is the one fully-shipped skill, with per-agent install paths (Copilot / Cline / Cursor / Claude Code) and a 5-prompt before/after test harness.
- [skills/general/pr-review/](skills/general/pr-review/), [skills/salesforce/](skills/salesforce/), [skills/mulesoft/](skills/mulesoft/) hold one example each — useful as references for the skill format.

### Competence map

[competence-map.yml](competence-map.yml) + [scripts/generate-competence-map.ps1](scripts/generate-competence-map.ps1). Depth is author-set; the generator refuses to render `expert` claims without backing evidence and downgrades anything untouched for 90+ days to dormant. CI rejects PRs that change the YAML without regenerating the page.

## The two-repo pattern (documentation, not tooling)

The privacy split is still the recommended way to run any memory system: keep private working state (observations, client names, active threads) in a **private** repo; promote only generalized, transferable lessons into a shared layer like this one. The promotion rule: *only promote a lesson if it would still apply in a language you haven't used yet.*

This repository must never contain personal working-state files (`observations.jsonl`, `active-threads.md`, `open-loops.md`, `decision-journal.md`, and friends). The `.gitignore` here protects those paths. See [docs/framework-scope.md](docs/framework-scope.md) for the full boundary.

The script tooling that used to automate this split (capture, sync, summon, weekly synthesis) was retired in June 2026 — editor-native memory now does the capture/inject job. The pattern remains; bring your own plumbing or rely on your agent's built-in memory.

## Operating principles

- **Evidence over claim.** Never accept "done" without independent verification — see [anti-hallucination-protocol.md](anti-hallucination-protocol.md).
- **Reject by default.** A memory that isn't reusable, atomic, novel, and actionable doesn't get stored. Storage is cheap; retrieval attention is not.
- **Caps over completeness.** Bounded lists force pruning; unbounded lists become wikis nobody reads.
- **Personal first, shared second.** Lessons earn their way out of the private layer by reuse and the transfer test.
- **Private data stays private.** Working state never lands in a shared repo.

## Community

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Code of conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Security policy: [SECURITY.md](SECURITY.md)

## Research and evolution

- Ecosystem landscape: [docs/memory-ecosystem-research-2026-05-15.md](docs/memory-ecosystem-research-2026-05-15.md)
- Competitive landscape: [docs/competitive-landscape-2026-05.md](docs/competitive-landscape-2026-05.md)
- Practical adoption protocol: [docs/memory-adoption-playbook.md](docs/memory-adoption-playbook.md)
- Skills templates: [skills/README.md](skills/README.md)

## Why this exists

Agent memory systems fail in two directions: manual second-brains demand discipline nobody has, and automatic ones store everything and drown in their own noise. The bet here is that the scarce, durable piece is **judgment about what deserves to be remembered** — encoded as a deterministic, testable gate that any storage layer can call. Native editor memory handles capture and recall now; this project supplies the part that says no.
