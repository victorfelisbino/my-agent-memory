# Probe B: Quality Gate PR to memory-bank-mcp

**Date:** 2026-05-26
**Status:** Approved
**Scope:** Port the admission gate scorer to TypeScript and contribute it as an opt-in quality gate to alioshr/memory-bank-mcp (905 stars, MIT, actively maintained).

---

## Context

memory-bank-mcp is a file-based MCP memory server with 905 stars. It stores memories as plain files with no quality filtering, deduplication, or scoring. The research confirms this is the universal pattern — everyone stores, nobody filters.

Our admission gate scorer (Python/PowerShell) achieves 100/100/100 accuracy on a 100-item fixture and 1.0% real-corpus rejection. Porting it to TypeScript and contributing it upstream tests whether the concept resonates with an existing community.

## Target Repository

- **Repo:** `alioshr/memory-bank-mcp`
- **Language:** TypeScript (ESM, ES2022 target)
- **Architecture:** Clean Architecture (domain/data/infra/presentation/validators/main)
- **Test framework:** Vitest
- **Runtime deps:** `@modelcontextprotocol/sdk`, `fs-extra` (we add zero new deps)
- **Build:** vanilla `tsc`
- **Published as:** `@allpepper/memory-bank-mcp` on npm

## Design

### New Files

```
src/
  domain/
    models/quality-score.ts              -- QualityScore interface
  data/
    usecases/score-memory.ts             -- ScoreMemory use case (40+ rules, 4 dimensions)
    usecases/write-file-gated.ts         -- Decorator around WriteFile
    usecases/update-file-gated.ts        -- Decorator around UpdateFile
  main/
    config/quality-gate.ts               -- Config reader (env vars)
    factories/score-memory-factory.ts    -- Factory for ScoreMemory
    factories/write-file-gated-factory.ts
    factories/update-file-gated-factory.ts

tests/
  data/usecases/score-memory.spec.ts     -- 20 fixture items (10 keep, 10 reject)
  data/usecases/write-file-gated.spec.ts -- Decorator behavior tests
  data/usecases/update-file-gated.spec.ts
  main/config/quality-gate.spec.ts       -- Config toggle tests
```

### Modified Files

```
src/main/factories/write-file-factory.ts   -- Conditionally return gated or plain use case
src/main/factories/update-file-factory.ts  -- Same
README.md                                  -- Document quality gate config
```

### Domain Model

```typescript
// src/domain/models/quality-score.ts
export interface QualityScore {
  decision: 'keep' | 'reject'
  total: number
  reusability: number
  atomicity: number
  novelty: number
  actionability: number
  reason: string
}
```

### Scorer Use Case

```typescript
// src/data/usecases/score-memory.ts
export class ScoreMemory {
  constructor(private readonly threshold: number) {}

  score(content: string): QualityScore {
    const reusability = this.scoreReusability(content)
    const atomicity = this.scoreAtomicity(content)
    const novelty = 0.0  // stubbed: no store access
    const actionability = this.scoreActionability(content)
    const total = reusability + atomicity + novelty + actionability
    const decision = total >= this.threshold ? 'keep' : 'reject'
    const reason = decision === 'reject' ? this.buildReason(reusability, atomicity, actionability) : ''
    return { decision, total, reusability, atomicity, novelty, actionability, reason }
  }

  // ... private rule methods
}
```

### Gated Decorator

```typescript
// src/data/usecases/write-file-gated.ts
export class WriteFileGated implements WriteFile {
  constructor(
    private readonly inner: WriteFile,
    private readonly scorer: ScoreMemory,
    private readonly logger?: (entry: object) => void
  ) {}

  async execute(params: WriteFileParams): Promise<WriteFileResult> {
    const score = this.scorer.score(params.content)
    if (this.logger) this.logger({ ...score, file: params.fileName, timestamp: new Date().toISOString() })
    if (score.decision === 'reject') {
      return {
        success: false,
        message: `Quality gate rejected (score: ${score.total.toFixed(2)}, threshold: ${this.scorer.threshold}). Reason: ${score.reason}. Reformulate the memory to be more reusable, atomic, and actionable.`
      }
    }
    return this.inner.execute(params)
  }
}
```

### Configuration

```typescript
// src/main/config/quality-gate.ts
export interface QualityGateConfig {
  enabled: boolean
  threshold: number
  logPath: string | null
}

export function loadQualityGateConfig(): QualityGateConfig {
  return {
    enabled: process.env.MEMORY_GATE_ENABLED === 'true',
    threshold: parseFloat(process.env.MEMORY_GATE_THRESHOLD || '0.5'),
    logPath: process.env.MEMORY_GATE_LOG || null,
  }
}
```

### Factory Modification

```typescript
// src/main/factories/write-file-factory.ts (modified)
import { loadQualityGateConfig } from '../config/quality-gate'
import { makeScoreMemory } from './score-memory-factory'
import { WriteFileGated } from '../../data/usecases/write-file-gated'

export function makeWriteFile(): WriteFile {
  const config = loadQualityGateConfig()
  const base = new WriteFileImpl(/* existing deps */)
  if (!config.enabled) return base
  const scorer = makeScoreMemory(config.threshold)
  const logger = config.logPath ? makeJsonlLogger(config.logPath) : undefined
  return new WriteFileGated(base, scorer, logger)
}
```

### Scoring Rules (ported from score_memory.py)

**Reusability (negative patterns — score -1.0 each, cap at -1.0):**
- Timestamps: `\b(today|yesterday|tomorrow|just now)\b`, `\b(at|on)\s+\d{1,2}[:.]\d{2}\b`, `\b20\d{2}-\d{2}-\d{2}\b`
- Machine names: `\b(office-pc|workstation|laptop-\w+)\b`
- File paths: `\bline\s+\d+\b`, `\bsrc/[a-zA-Z0-9_./-]+`, `\bfeature/[a-zA-Z0-9._-]+`
- Sprint refs: `\bsprint-?\d+\b`
- Named persons: `\b(named|aged?\s+\d+|years old|lives in)\b`
- Client names: `\bacme\b|\bcustomer-\w+\b`
- Positive baseline: +0.3 when no negative patterns match

**Atomicity (sentence-based):**
- 1 sentence: +0.3
- 2-3 sentences: +0.1
- 4+ sentences: -0.5
- Contains semicolons (structured): +0.1 bonus

**Novelty:**
- Stubbed at 0.0 (no store access in this integration)
- Documented as a known limitation; full implementation requires search capability

**Actionability (pattern-based):**
- Vague truisms (`matters|important|should care`): -1.0
- Empty agreements (`ok|sounds good|got it|sure`): -1.0
- Self-referential (`agent|assistant|I provided|I helped`): -1.0
- Greetings (`thanks|hello|hi there|let me know`): -1.0
- Self-praise (`excellent|perfect|great job` from agent): -1.0
- Confidence-only (`I'm \d+% sure|confident`): -1.0
- Contains specific practices (`:` separator, `must|always|never` + technical noun): +0.5
- Contains tool/package names: +0.25
- Positive baseline: +0.0 when no patterns match

**Threshold:** total >= 0.5 → keep; total < 0.5 → reject.

### Tests

**score-memory.spec.ts** — 20 items from our v4 fixture:

Keep examples:
1. "Avalonia DataGrid is a separate NuGet package; must dotnet add package Avalonia.Controls.DataGrid before using it."
2. "Salesforce: always check field-level security after an Apex deploy."
3. "Never accept 'done' claims without independent verification."
4. "Prefer streaming generators over building a full list when the input may be larger than memory."
5. "Windows PowerShell 5.1 reads .ps1 files as ANSI unless they have a UTF-8 BOM."
6-10. More from fixture...

Reject examples:
1. "Session started 2026-05-26 at 09:00 on office-pc."
2. "Currently reading file src/foo.ts at line 42."
3. "Code quality matters and we should care about it."
4. "Agent answered the user's question with confidence today."
5. "Thanks! Let me know if you need anything else."
6-10. More from fixture...

**write-file-gated.spec.ts:**
- Gate enabled + good content → delegates to inner WriteFile
- Gate enabled + bad content → returns rejection message without writing
- Gate disabled → always delegates to inner WriteFile
- Logger receives entries for both keep and reject decisions

### PR Description Template

```markdown
## Add optional quality gate for memory writes

### Problem

Every memory system stores indiscriminately. mem0's documented [97.8% junk rate](https://github.com/mem0ai/mem0/issues/4573) in production demonstrates the failure mode: without a write-time filter, noise drowns signal and agent memory degrades over time.

### Solution

An opt-in quality gate that scores memory content on four dimensions before allowing writes:

- **Reusability** — would this help in a future session?
- **Atomicity** — is it one discrete fact?
- **Novelty** — (stubbed; requires search capability for full implementation)
- **Actionability** — does it change behavior?

Below threshold → rejected with a reason and score breakdown, so the agent can reformulate.

### Usage

```bash
# Enable the gate (off by default — zero impact on existing users)
MEMORY_GATE_ENABLED=true

# Optional: adjust threshold (default 0.5)
MEMORY_GATE_THRESHOLD=0.5

# Optional: audit log
MEMORY_GATE_LOG=/path/to/scoring.jsonl
```

### Evidence

This scorer achieves 100% accuracy on a [100-item labeled fixture](https://github.com/victorfelisbino/my-agent-memory/tree/main/admission-gate/fixtures) (50 keep, 50 reject) covering documented junk categories. On a 381-item real corpus, rejection rate is 1.0% (all defensible).

### Before / After

| Memory | Decision | Reason |
|--------|----------|--------|
| "Session started 2026-05-26 at 09:00 on office-pc." | REJECT | reusability=-1 (timestamp + machine name) |
| "Code quality matters and we should care about it." | REJECT | actionability=-1 (vague truism) |
| "Avalonia DataGrid is a separate NuGet package; must install before use." | KEEP | score=0.85 (reusable, atomic, actionable) |

### Design decisions

- **Opt-in**: `MEMORY_GATE_ENABLED=true` activates. Off by default.
- **Decorator pattern**: Wraps existing WriteFile/UpdateFile use cases. No changes to core logic paths.
- **Zero new dependencies**: All scoring is regex/heuristic based, no ML models or external calls.
- **Novelty stubbed**: Full contradiction detection requires search/read-all capability. Documented as a future extension point once Issue #1 (RAG) ships.

### References

- mem0 junk audit: https://github.com/mem0ai/mem0/issues/4573
- Scorer source (Python/PowerShell): https://github.com/victorfelisbino/my-agent-memory/tree/main/admission-gate
- Evidence and methodology: https://victorfelisbino.github.io/my-agent-memory/evidence/
```

---

## Success Criteria

1. PR is well-structured, follows their Clean Architecture, includes Vitest tests, adds zero deps
2. `npm run test` and `npm run build` pass
3. PR is opened with the description above referencing the evidence
4. Track: reviewed within 2 weeks? Merged? Requested changes? Outside engagement?

## Kill Switch

If the maintainer rejects on concept (not style), the quality-gate-as-middleware idea doesn't resonate with this audience. Pivot to contributing directly to mem0 (#4573) or ship the standalone MCP server (Wave 5-A early start).

## Implementation Order

1. Fork memory-bank-mcp, set up local dev environment
2. Port scoring rules to TypeScript (single file, pure function, no deps)
3. Write ScoreMemory use case + tests (verify against our fixture)
4. Write gated decorators + tests
5. Wire into factories with config toggle
6. Update README
7. Run full test suite + build
8. Open PR
