# try it

<div class="landing-shell">
	<div class="landing-grid">
		<div class="hero-copy">
			<h1>Score your memory corpus in 60 seconds.</h1>
			<p class="lead">Clone the repo, pipe a memory through the scorer, see the decision. No dependencies beyond Python 3.8+.</p>
			<div class="pill-row">
				<span class="pill">Python 3.8+</span>
				<span class="pill">Zero dependencies</span>
				<span class="pill">Pipe-friendly</span>
			</div>
		</div>
		<div class="kpi-panel">
			<div class="kpi-item">
				<strong>3 commands to first result</strong>
				<span>Clone, cd, pipe. No pip install, no config, no API key.</span>
			</div>
			<div class="kpi-item">
				<strong>Exit code contract</strong>
				<span>0 = keep, 3 = reject. Wire into any shell script or CI pipeline.</span>
			</div>
			<div class="kpi-item">
				<strong>JSON in, JSON out</strong>
				<span>stdin accepts <code>{"text":"..."}</code>, stdout emits decision + score + dimensions.</span>
			</div>
		</div>
	</div>
</div>

## Quick start

```bash
git clone https://github.com/victorfelisbino/my-agent-memory.git
cd my-agent-memory/admission-gate

# Score a single memory
echo '{"text":"Always use try-catch in JavaScript"}' | python3 score_memory.py --score-one
```

Windows PowerShell equivalent:

```powershell
git clone https://github.com/victorfelisbino/my-agent-memory.git
cd my-agent-memory\admission-gate

# Score a single memory
echo '{"text":"Always use try-catch in JavaScript"}' | python score_memory.py --score-one
```

**Output:**
```json
{"scorer":"py","decision":"keep","total":1.1,"reusability":0.3,"atomicity":0.3,"novelty":0.0,"actionability":0.5,"reason":""}
```

Now try a garbage memory:

```bash
echo '{"text":"Session started 2026-05-26 at 09:00 on office-pc."}' | python3 score_memory.py --score-one
```

Windows PowerShell equivalent:

```powershell
echo '{"text":"Session started 2026-05-26 at 09:00 on office-pc."}' | python score_memory.py --score-one
```

**Output:**
```json
{"scorer":"py","decision":"reject","total":-0.7,"reusability":-1.0,"atomicity":0.3,"novelty":0.0,"actionability":0.0,"reason":"reusability=-1"}
```

Exit code 3 — your pipeline knows to discard it.

## Score your own corpus

If you have memories in markdown files:

```bash
# Extract atomic bullets from .md files into JSONL
pwsh extract-corpus.ps1 -Path /path/to/your/memory-files -OutFile my-corpus.jsonl

# Score the full corpus
python3 score_memory.py --fixture my-corpus.jsonl --unlabeled
```

Windows PowerShell equivalent:

```powershell
# Extract atomic bullets from .md files into JSONL
.\extract-corpus.ps1 -Path C:\path\to\your\memory-files -OutFile my-corpus.jsonl

# Score the full corpus
python score_memory.py --fixture my-corpus.jsonl --unlabeled
```

If your memories are already in JSONL (one `{"text":"..."}` per line):

```bash
python3 score_memory.py --fixture your-memories.jsonl --unlabeled
```

Windows PowerShell equivalent:

```powershell
python score_memory.py --fixture your-memories.jsonl --unlabeled
```

The `--unlabeled` flag means items don't need `label` fields — the scorer just reports its decision for each.

## Set a quality bar

Use `--fail-under` to gate your pipeline:

```bash
# Fail (exit 3) if accuracy drops below 85% on your labeled test set
python3 score_memory.py --fixture test-set.jsonl --fail-under 85
```

Windows PowerShell equivalent:

```powershell
python score_memory.py --fixture test-set.jsonl --fail-under 85
```

## Add contradiction detection

Pass your existing memory store so the scorer can detect conflicts:

```bash
echo '{"text":"Never use strict mode in production."}' \
  | python3 score_memory.py --score-one --store existing-memories.jsonl
```

Windows PowerShell equivalent:

```powershell
echo '{"text":"Never use strict mode in production."}' |
	python score_memory.py --score-one --store existing-memories.jsonl
```

If your store contains "Always use strict mode" — contradiction detected, candidate rejected.

## Add feedback-loop prevention

Pass the memories recalled in the current session:

```bash
echo '{"text":"Always validate input at system boundaries."}' \
  | python3 score_memory.py --score-one --recalled session.jsonl
```

Windows PowerShell equivalent:

```powershell
echo '{"text":"Always validate input at system boundaries."}' |
	python score_memory.py --score-one --recalled session.jsonl
```

If this principle was already recalled and is now being re-ingested — feedback loop detected, candidate rejected.

## Audit trail

Log every decision for review:

```bash
echo '{"text":"..."}' | python3 score_memory.py --score-one --log-to scoring-log.jsonl
```

Windows PowerShell equivalent:

```powershell
echo '{"text":"..."}' | python score_memory.py --score-one --log-to scoring-log.jsonl
```

Then render a local dashboard:

```powershell
.\render-dashboard.ps1
# → opens dashboard.html (self-contained, no server needed)
```

## Wire into your capture pipeline

The scorer is designed to sit between your capture step and your storage:

```bash
#!/bin/bash
# Example: gate every captured observation
MEMORY_TEXT="$1"
RESULT=$(echo "{\"text\":\"$MEMORY_TEXT\"}" | python3 score_memory.py --score-one)
EXIT=$?

if [ $EXIT -eq 0 ]; then
    echo "$MEMORY_TEXT" >> observations.jsonl
else
    REASON=$(echo "$RESULT" | python3 -c "import sys,json;print(json.load(sys.stdin).get('reason',''))")
    echo "Rejected: $REASON"
    echo "$MEMORY_TEXT" >> observations.rejected.jsonl
fi
```

Or use the built-in capture scripts that already have the gate wired in:

```bash
# Manual capture (gated by default)
./capture-observation.sh "Lesson learned about X"

# Bypass the gate when you know what you're doing
./capture-observation.sh --no-gate "Force-store this observation"
```

## Bonus: anti-hallucination skill

While the gate filters your writes, you can also improve your agent's reads. The anti-hallucination skill prevents the four most common hallucination shapes in coding agents.

Copy the skill into your agent config:

- **Copilot:** paste into `.github/copilot-instructions.md`
- **Cline:** paste into `.clinerules`
- **Cursor:** paste into `.cursorrules`
- **Claude Code:** paste into `CLAUDE.md`

See the full [install paths](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/install.md) and [test harness](https://github.com/victorfelisbino/my-agent-memory/blob/main/skills/general/anti-hallucination/test-prompts.md) (5/5 pass on GPT-4.1).
