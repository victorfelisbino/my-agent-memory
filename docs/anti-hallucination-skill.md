# Anti-hallucination skill

The first **shipped** skill out of the [roadmap](roadmap.md) Wave 1 work. It converts [`anti-hallucination-protocol.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/anti-hallucination-protocol.md) from a write-up into a load-it-yourself block that any agent with a system / instructions prompt can consume.

## What it does

It biases the agent to refuse the four hallucination shapes that show up most often in coding work:

1. **Invented surface area** — APIs, file paths, config keys, env vars the agent has not actually seen.
2. **"Should work" without proof** — confident deploy / merge / "you're good" verdicts with no verification step.
3. **Admin-only proof** — passing a check as admin and declaring permissions complete.
4. **"No issues found" without running a check** — generic clean bills of health.

It also asks the agent to ask for missing constraints up front (batched), separate facts / assumptions / unknowns explicitly when the task is risky, and end complex answers with verification steps.

## Where it lives in the repo

- [`skills/general/anti-hallucination/skill.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/skill.md) &mdash; the copy-paste block plus front-matter.
- [`skills/general/anti-hallucination/install.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/install.md) &mdash; one-step install paths for Copilot custom instructions, Cline `.clinerules`, Cursor `.cursorrules`, and manual one-off use.
- [`skills/general/anti-hallucination/test-prompts.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/test-prompts.md) &mdash; the five-prompt before/after harness with binary pass/fail rules.
- [`skills/general/anti-hallucination/results-template.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/results-template.md) &mdash; what you fill in when you run the harness.

## How to verify it actually works in your setup

Run the five prompts in [`test-prompts.md`](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/test-prompts.md) twice each: once with the skill loaded, once without. Score with the binary rules provided.

The roadmap's exit criterion for Wave 1 is **"a reproducible demo where the same prompt gets a measurably better answer with the skill loaded."** Target is 3 of 5 prompts passing with the skill loaded and failing without it. Anything less is real signal that the skill is decorative and needs sharpening &mdash; report it as an issue.

## What is NOT yet automated

- **Auto-injection by `summon-memory`.** Today it's load-it-yourself. The roadmap Wave 4-A item ("Copilot Guardrail Layer" MCP server) is where auto-injection becomes the default.
- **Cross-agent comparison.** Results-template captures one agent at a time. Aggregating across Copilot vs Cline vs Cursor is manual.
- **Continuous regression.** No CI runs the harness. Treat your last results entry as a point-in-time snapshot.

These are all explicit gaps tracked in [Status](status.md) under "Documented only."

## Where this goes next

Wave 2 of the roadmap is the public probe: open a PR contributing this skill to [`groupzer0/vs-code-agents`](https://github.com/groupzer0/vs-code-agents) and read the signal. If it lands and gets engagement, Wave 4-A pivots `my-agent-memory` into the "Copilot Guardrail Layer" architecture that auto-injects this and similar skills via an MCP server. If it doesn't, Wave 4-C archives gracefully. See [Roadmap](roadmap.md) for the kill-switch logic.
