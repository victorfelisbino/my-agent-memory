# Copilot Auto-Mode Strategy

GitHub Copilot's **auto** model mode picks a model per request and applies roughly a 10% discount on premium usage. This memory system is designed to make auto-mode *work*, not just be cheaper.

## Why auto-mode usually drifts (and burns tokens)

Without good context, the auto-router has to either:
- Default to the heaviest model "to be safe" (no discount benefit, you pay more), or
- Pick a cheap model that then drifts, asks 3 clarifying questions, retries twice, and costs more than if you'd just picked the right model yourself.

Either way, you lose. The router needs **structured task metadata** in the prompt to classify cheaply and pick correctly the first time.

## How this repo helps

[summon-memory.ps1](summon-memory.ps1) emits a **router-hints header** at the top of every brief:

```
## Router hints (for Copilot auto-mode)
- Task type : debug | refactor | review | design | test | explain | generate
- Complexity: trivial | standard | complex
- Domain    : General | Salesforce | MuleSoft
- Suggested : fast | balanced | reasoning | deep
- Task      : <your one-line task>
```

The auto-router reads this and biases its choice. Empirically the suggested-model field nudges it strongly, but even without that the structured classification alone makes routing more consistent.

## Two modes, two budgets

| Mode    | Snippets | Observations | Active threads | Score breakdown | Typical size |
|---------|---------:|-------------:|---------------:|----------------:|-------------:|
| full    | 10       | 5            | yes (top 5)    | yes             | ~1000-1500 tokens |
| compact | 5        | 3            | dropped        | stripped        | ~250-400 tokens |

`full` is for non-trivial work where the brief's signal is worth the tokens. `compact` is the default for quick tasks — same router hints, ~70% fewer tokens.

```powershell
.\summon-memory.ps1 -Task "fix the deployment error in staging" -Compact -Preflight
```

## When to use which mode

- **Trivial / well-bounded** (rename, typo, single small function): `-Compact`. Router will pick a small model and the brief won't bloat the prompt.
- **Complex / multi-step / cross-cutting**: full brief. The score breakdowns and active-threads list help auto-mode justify routing to a deeper model and give it more context to avoid retries.
- **Pure conversation / "explain this code"**: skip summon-memory entirely. Auto-mode handles it cheaply on its own.

## Drift prevention is the real saver

Tokens spent on a too-cheap model that drifts dwarf the tokens saved by being cheap. The biggest cost reducers in this system are not the discount, they are:

1. **Stay-scoped instruction** in the preflight prompt: *"Do not expand scope without asking."* Cuts unsolicited refactors.
2. **One-batched-question rule**: *"If required values are org/project-specific, ask for them explicitly (one batched question, not many)."* Cuts back-and-forth round trips.
3. **Skip-restating instruction**: *"Skip restating context back to me. Go straight to the answer."* Cuts the polite-but-expensive recap.
4. **Anti-hallucination guardrails** from [anti-hallucination-protocol.md](anti-hallucination-protocol.md) auto-included by relevance scoring. Cuts retries caused by invented file paths, APIs, or component names.

Even on a heavy model, these four reliably cut a 4-turn conversation to 1-2 turns.

## Recommended VS Code settings

- Set the default model to **auto** in the Copilot Chat picker. Override per-conversation only when you have a specific reason.
- Bind a keybinding to `summon-memory.ps1 -Compact -Preflight` for one-shot context injection.
- Run the daily `MemoryDailySync` scheduled task so [`observations.jsonl`](observations.jsonl) and [`active-threads.md`](active-threads.md) stay fresh — stale observations hurt routing accuracy.

## Measuring whether this works

Track these in your own use over a week:
- **Avg turns to resolution** for "standard" tasks (target: 1-2).
- **% of sessions where auto picked a deep model when a cheap one would do** (target: <20%).
- **% of sessions where you manually overrode auto** (target: <30% after a week of tuning).

If those numbers don't improve, the router-hints aren't being read or the brief is wrong; revisit task-type classifier rules in [summon-memory.ps1](summon-memory.ps1#L75).
