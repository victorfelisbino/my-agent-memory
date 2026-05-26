# Competitive Landscape (May 2026)

**Purpose:** Snapshot of the AI agent memory ecosystem. Used to inform roadmap decisions. Refresh quarterly or when a competitor ships something relevant.

**Last updated:** 2026-05-26

---

## The core insight

Every memory system stores indiscriminately. Nobody filters. The #1 project (mem0, 56.8k stars) has a [documented 97.8% junk rate](https://github.com/mem0ai/mem0/issues/4573) in production. The market needs a quality gate, not another storage layer.

---

## Storage layer (solved problem — don't compete here)

| Project | Stars | Architecture | MCP? | Quality Gate |
|---------|-------|-------------|------|-------------|
| **mem0** | 56.8k | Vector + BM25 + entity linking. Single-pass extraction. Python/TS SDKs. Cloud + self-hosted + library modes. | No | Hash dedup only. 97.8% junk in production audits. |
| **Letta (MemGPT)** | 23k | Stateful agents with memory blocks. API-first. Python/TS SDKs. Docker. | No | None. |
| **Zep** | 4.6k | Temporal knowledge graph (Graphiti). valid_at/invalid_at dates. SOC2/HIPAA cloud. | Yes (MCP server ships) | Temporal validity only. Community OSS deprecated. |
| **Official MCP Memory** | (86k servers repo) | Knowledge graph in JSONL. 9 tools. Entities + relations + observations. | Yes (reference impl) | None. Minimal, unopinionated. |
| **memory-bank-mcp** | 905 | File-based multi-project MCP server. 5 tools. TypeScript. Cline-inspired. | Yes | None. Raw read/write. |

### mem0 deep dive (our strongest validation)

- **New algorithm (April 2026):** Single-pass ADD-only extraction, entity linking, multi-signal retrieval, temporal reasoning. Benchmarks: 91.6 LoCoMo, 94.8 LongMemEval, 64.1 BEAM.
- **Quality problem (issue #4573):** Audit of 10,134 entries over 32 days. 52.7% boot prompt regurgitation, 11.5% heartbeat/cron noise, 5.2% hallucinated user profiles, 808 copies of "User prefers Vim" (nobody does). Switching to Claude Sonnet 4.6 didn't help — better model extracts more indiscriminately.
- **Proposed fixes (from the issue):** feedback loop prevention, quality gate between extraction and storage, negative few-shot examples, REJECT action, identity-aware extraction. None implemented as of May 2026.
- **No MCP support.** Uses its own SDK/API.
- **Agent integrations:** Claude Code, Codex, Cursor, Windsurf, OpenCode via "skills" system.

---

## Quality layer (unsolved problem — our niche)

| Project | Stars | Approach | Maturity |
|---------|-------|----------|----------|
| **Tensory** | 4 | Claim-native: LLM extraction, salience scoring, Graph + Vector + SQLite. Collision detection. Memory decay. MCP server. | Alpha. 330+ tests. 82.2% LoCoMo. |
| **engram** | 0 | Decay, recall, compression, versioning. TypeScript. | Nascent. |
| **Muninn** | 0 | Local-first. Deterministic retrieval. Explainable traces. MCP/REST/SDK. | Nascent. |
| **Us (my-agent-memory)** | — | Anti-hallucination skill (shipped). Competence map (building). Admission gate + contradiction detection + feedback loop prevention (designed). Transfer-test promotion (concept). | Wave 1 shipped. Waves 2.5 + 3 next. |

### Tensory (closest competitor)

- Claim-level extraction with salience scores (not chunk-based)
- Contradiction/collision detection built in
- Salience decay (algorithmic, zero LLM calls)
- Full cognitive stack: episodic, semantic, procedural memory + reflection
- Claude Code plugin via hooks (no manual tool calls)
- LoCoMo benchmark: 82.2%
- Cost: ~$0.08/conversation (Haiku + embeddings)
- **Risk:** If they get traction, our path narrows. Currently alpha with 4 stars.

---

## IDE-native memory (what ships built-in)

### Claude Code (most sophisticated)

- **CLAUDE.md:** Multi-tier (managed policy, user, project, local). Loaded every session. @import syntax. Path-scoped rules via `.claude/rules/`.
- **Auto memory:** Claude writes learnings to `~/.claude/projects/<project>/memory/`. 200-line cap on MEMORY.md (topic files loaded on-demand). Per-project, machine-local.
- **Subagent memory:** Subagents can maintain their own persistent memory.
- **No quality gate:** Relies on LLM judgment about what's "worth remembering."
- **Hook system:** `InstructionsLoaded` and other lifecycle events. Possible integration path for our quality gate.

### GitHub Copilot

- **copilot-instructions.md:** Repository-wide custom instructions in `.github/`.
- **Path-specific instructions:** `NAME.instructions.md` with glob patterns.
- **AGENTS.md:** Agent instructions (nearest file in directory tree wins).
- **No memory, no learning, no persistence.** Purely static file injection. No MCP support.

### Cursor

- **.cursor/rules:** Project-level instruction files. MCP client support.
- **No cross-session memory.** Static rules only.

### Cline (62.4k stars)

- **.clinerules:** Project conventions, auto-picked-up.
- **Skills system:** Load specific rules on demand.
- **"Memory bank" is a community pattern,** not built-in. Users manually maintain markdown files.
- **Team state:** Persists across sessions for multi-agent teams.
- **MCP client support.**

### OpenAI Codex CLI (85.9k stars)

- **AGENTS.md:** Project-level instructions.
- **Rust-based (96%).** Desktop + CLI + VS Code extension.
- **No documented persistent memory system.**

---

## MCP ecosystem health

- **86.3k stars** on modelcontextprotocol/servers
- **10 official SDKs** (C#, Go, Java, Kotlin, PHP, Python, Ruby, Rust, Swift, TypeScript)
- **40+ registries and directories** (Smithery, mcp.run, OpenTools, PulseMCP, MCPHub, etc.)
- **MCP clients:** Cline, Cursor, Claude Desktop, Claude Code all speak MCP
- **MCP NOT supported by:** Copilot (uses AGENTS.md), Codex CLI
- **Verdict:** MCP is the right transport for Wave 5-A. Copilot needs a parallel native path.

---

## User pain points (from issues, discussions, audits)

1. **Memory quality / junk accumulation** — the #1 complaint across all systems
2. **Feedback loops** — recalled context gets re-extracted as new memory
3. **No way to know what's stored** — audit/transparency tools are weak
4. **Cost visibility** — token usage for memory extraction isn't reported
5. **Internationalization** — mem0's BM25 and entity extraction are English-only
6. **Batch operations missing** — can't bulk-manage memories
7. **Cross-session persistence** — agents forget between sessions (IDE-native partially solves this)
8. **Contradiction handling** — storing conflicting facts without flagging them

---

## Our competitive moat (defensible)

1. **Anti-hallucination injection as a testable skill** — agent-agnostic, before/after harness, copy-paste install. Nobody else packages this.
2. **Competence map** — machine-readable expertise inventory with honesty enforcement. No competitor publishes "what this brain knows" with computed evidence.
3. **Admission gate philosophy** — the thesis that "saying no is the product." Validated by mem0's 97.8% junk rate.
4. **Transfer-test promotion** — a lesson must generalize beyond one context before promotion. Intellectually strong, nobody implements it.
5. **Feedback loop prevention** — tracking recalled memories to prevent re-ingestion. Proposed in mem0 #4573 but not built.

## What we DON'T uniquely have (contested)

- Memory storage (everyone does this)
- Cross-session persistence (IDE-native now)
- Knowledge graphs (Zep, Tensory, MCP reference)
- MCP transport (Tensory ships this)
- Salience scoring (Tensory has this)
- Contradiction detection (Tensory has this)

---

## Strategic implications for roadmap

- **Build the quality gate, not another store.** Our moat is curation.
- **Competence map is a unique wedge.** Nobody else publishes "what does this brain know?" with evidence. This makes the repo forkable and legible.
- **Target MCP + Copilot dual path.** MCP covers Cline/Cursor/Claude; Copilot needs native injection.
- **Watch Tensory.** If they break out of alpha, consider contributing rather than competing.
- **mem0 #4573 is a market signal.** If they don't address it, there's a PR opportunity (Path B) and a positioning opportunity (Path A).
- **Claude Code hooks are an integration path** that doesn't require MCP. Quality gate on auto-memory writes.
