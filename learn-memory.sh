#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_STORAGE_ROOT="${HOME}/Library/Application Support/Code/User/workspaceStorage"
TRANSCRIPT_DIR=""
OUTPUT_DIR="${SCRIPT_DIR}"

usage() {
  echo "Usage: $0 [--workspace-root <path>] [--transcript-dir <path>] [--output-dir <path>]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace-root)
      WORKSPACE_STORAGE_ROOT="${2:-}"
      shift 2
      ;;
    --transcript-dir)
      TRANSCRIPT_DIR="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

python3 - "$WORKSPACE_STORAGE_ROOT" "$TRANSCRIPT_DIR" "$OUTPUT_DIR" <<'PY'
import datetime
import json
import pathlib
import re
import sys

workspace_root = pathlib.Path(sys.argv[1]).expanduser()
transcript_dir_arg = sys.argv[2].strip()
output_dir = pathlib.Path(sys.argv[3]).expanduser()

patterns = [
    {"triggers": [r"\\bdid\\s+it\\s+deploy\\b", r"\\bdeployed\\s*\\?"], "trigger_display": "did it deploy|deployed?", "label": "False deploy confidence", "severity": "P0", "domain": "General", "guardrail": "Require branch, PR diff, and org deploy report before closure."},
    {"triggers": [r"\\bdeploy(?:ment|ed|ing)?\\b"], "trigger_display": "deploy*", "label": "Deploy churn", "severity": "P1", "domain": "General", "guardrail": "Use pre-close verification bundle every time."},
    {"triggers": [r"\\bqa\\b"], "trigger_display": "qa", "label": "QA promotion risk", "severity": "P1", "domain": "Salesforce", "guardrail": "Confirm branch diff against qa before PR."},
    {"triggers": [r"\\bpr\\b", r"\\bpull\\s+request\\b"], "trigger_display": "pr|pull request", "label": "PR workflow confusion", "severity": "P1", "domain": "General", "guardrail": "Check PR delta exists before opening/reviewing."},
    {"triggers": [r"\\bbranch(?:es)?\\b"], "trigger_display": "branch", "label": "Branch drift", "severity": "P1", "domain": "General", "guardrail": "Track base and head branch parity before promotion."},
    {"triggers": [r"\\bgearset\\b"], "trigger_display": "gearset", "label": "Gearset propagation misses", "severity": "P1", "domain": "Salesforce", "guardrail": "Back-propagate bot/suggestion commits to base branch."},
    {"triggers": [r"\\bmain_-_stg\\b"], "trigger_display": "main_-_stg", "label": "Staging branch validation failures", "severity": "P1", "domain": "Salesforce", "guardrail": "Audit first failing component before retrigger."},
    {"triggers": [r"\\bvalidat(?:e|ion|ing|ed)\\b"], "trigger_display": "validation", "label": "Validation loop repeats", "severity": "P1", "domain": "General", "guardrail": "Capture root cause before rerun."},
    {"triggers": [r"\\bfailed\\b", r"\\bfailure\\b"], "trigger_display": "failed|failure", "label": "Failure without diagnosis", "severity": "P1", "domain": "General", "guardrail": "Log first failing metadata component and owner."},
    {"triggers": [r"\\bprofile(?:s)?\\b"], "trigger_display": "profile", "label": "Profile metadata cross-reference errors", "severity": "P1", "domain": "Salesforce", "guardrail": "Audit profileActionOverrides/profile refs pre-deploy."},
    {"triggers": [r"\\bpermission(?:s)?\\b", r"\\bfls\\b"], "trigger_display": "permission|fls", "label": "Permission visibility mismatch", "severity": "P1", "domain": "General", "guardrail": "Validate FLS + perm assignment + layout/page activation."},
    {"triggers": [r"\\blayout(?:s)?\\b", r"\\brecord\\s+page\\b"], "trigger_display": "layout|record page", "label": "Layout-only fixes miss access path", "severity": "P1", "domain": "General", "guardrail": "Test as target persona, not admin only."},
    {"triggers": [r"\\btry\\s+again\\b", r"\\bretry\\b"], "trigger_display": "try again|retry", "label": "Retry without learning", "severity": "P2", "domain": "General", "guardrail": "Require one-line root cause hypothesis before retry."},
    {"triggers": [r"\\bmulesoft\\b", r"\\banypoint\\b", r"\\bapi\\s+manager\\b"], "trigger_display": "mulesoft|anypoint|api manager", "label": "MuleSoft platform friction", "severity": "P1", "domain": "MuleSoft", "guardrail": "Confirm environment, contract version, and deployment path before changes."},
    {"triggers": [r"\\bpolicy\\b", r"\\bpolicies\\b"], "trigger_display": "policy|policies", "label": "MuleSoft policy mismatch", "severity": "P1", "domain": "MuleSoft", "guardrail": "Diff applied policies across environments before promotion."},
    {"triggers": [r"\\bconnector\\b", r"\\bauth\\b", r"\\boauth\\b"], "trigger_display": "connector|auth", "label": "MuleSoft connector/auth drift", "severity": "P1", "domain": "MuleSoft", "guardrail": "Verify connector and auth config parity per environment."},
    {"triggers": [r"\\bschema\\b", r"\\bmapping\\b", r"\\braml\\b"], "trigger_display": "schema|mapping|raml", "label": "MuleSoft contract or mapping mismatch", "severity": "P1", "domain": "MuleSoft", "guardrail": "Run contract and payload mapping smoke checks before release."},
]

if transcript_dir_arg:
    tdir = pathlib.Path(transcript_dir_arg).expanduser()
    if not tdir.exists():
        raise SystemExit(f"Transcript directory not found: {tdir}")
    transcript_dirs = [tdir]
else:
    if not workspace_root.exists():
        raise SystemExit(f"Workspace storage root not found: {workspace_root}")
    transcript_dirs = []
    for entry in workspace_root.iterdir():
        if not entry.is_dir():
            continue
        candidate = entry / "GitHub.copilot-chat" / "transcripts"
        if candidate.exists():
            transcript_dirs.append(candidate)

if not transcript_dirs:
    raise SystemExit("No transcript directories found.")

messages = []
for tdir in dict.fromkeys(transcript_dirs):
    for jsonl in tdir.glob("*.jsonl"):
        try:
            with jsonl.open("r", encoding="utf-8") as fh:
                for line in fh:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    if obj.get("type") != "user.message":
                        continue
                    text = (((obj.get("data") or {}).get("content")) or "").lower()
                    if text:
                        messages.append(text)
        except OSError:
            continue

if not messages:
    raise SystemExit("No user messages found in transcript files.")

severity_weight = {"P0": 3, "P1": 2, "P2": 1}
rows = []
for p in patterns:
    compiled = [re.compile(expr) for expr in p["triggers"]]
    count = sum(1 for msg in messages if any(rx.search(msg) for rx in compiled))
    rows.append({
        "severity": p["severity"],
        "domain": p["domain"],
        "pattern": p["label"],
        "trigger": p["trigger_display"],
        "count": count,
        "guardrail": p["guardrail"],
    })

ranked = sorted(
    rows,
    key=lambda r: (r["count"] * severity_weight[r["severity"]], r["count"]),
    reverse=True,
)
top20 = ranked[:20]

now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
scoreboard_path = output_dir / "memory-scoreboard.md"
top_patterns_path = output_dir / "memory-top-patterns.md"

scoreboard_lines = [
    "# Memory Scoreboard",
    "",
    f"Updated: {now}",
    "",
    "| Priority | Severity | Domain | Pattern | Trigger | Count | Guardrail |",
    "|---|---|---|---|---|---:|---|",
]

for idx, row in enumerate(top20, start=1):
    scoreboard_lines.append(
        f"| {idx} | {row['severity']} | {row['domain']} | {row['pattern']} | {row['trigger']} | {row['count']} | {row['guardrail']} |"
    )

scoreboard_path.write_text("\n".join(scoreboard_lines) + "\n", encoding="utf-8")

top_lines = [
    "# Top Failure Patterns",
    "",
    f"Updated: {now}",
    "",
]

for row in top20:
    if row["count"] <= 0:
        continue
    top_lines.extend([
        f"## [{row['severity']}] {row['pattern']}",
        f"- Domain: {row['domain']}",
        f"- Trigger: {row['trigger']}",
        f"- Frequency: {row['count']}",
        f"- Guardrail: {row['guardrail']}",
        "- Action: Add or enforce this in gotchas.md and project-commands.md if missing.",
        "",
    ])

top_patterns_path.write_text("\n".join(top_lines) + "\n", encoding="utf-8")

print(f"Updated: {scoreboard_path}")
print(f"Updated: {top_patterns_path}")
print(f"Messages processed: {len(messages)}")
print(f"Transcript directories scanned: {len(set(transcript_dirs))}")
PY
