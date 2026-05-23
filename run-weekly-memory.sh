#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT=false
PUSH=false
COMMIT_MESSAGE="memory: weekly refresh"

usage() {
  echo "Usage: $0 [--commit] [--push] [--message <text>]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit)
      COMMIT=true
      shift
      ;;
    --push)
      PUSH=true
      shift
      ;;
    --message)
      COMMIT_MESSAGE="${2:-}"
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

cd "$SCRIPT_DIR"

echo "[1/5] Pull latest memory..."
git pull

echo "[2/6] Run learner..."
./learn-memory.sh

if [[ -x "./lint-memory.sh" && -d "./team-memory" ]]; then
  echo "[3/6] Run team memory lint..."
  ./lint-memory.sh --include-canonical
fi

echo "[4/6] Stage weekly memory files..."
files_to_stage=(
  memory-scoreboard.md
  memory-top-patterns.md
  gotchas.md
  salesforce-debugging.md
  project-commands.md
  README.md
  anti-hallucination-protocol.md
  thinking-principles.md
  decision-framework.md
  cognitive-bias-checks.md
  exploration-modes.md
  goals.md
  performance-map.md
  decision-journal.md
  weekly-review-checklist.md
  lesson-template.md
  docs/memory-adoption-playbook.md
  docs/memory-ecosystem-research-2026-05-15.md
  lint-memory.ps1
  lint-memory.sh
)

for f in "${files_to_stage[@]}"; do
  if [[ -e "$f" ]]; then
    git add "$f"
  fi
done

if [[ -d "team-memory" ]]; then
  git add team-memory
fi

echo "[5/6] Show staged status..."
git status --short

echo
echo "Weekly quality prompts (quick review):"
echo "- Did I update goals.md for this week?"
echo "- Did I log one decision in decision-journal.md?"
echo "- Did I add one anti-hallucination guardrail or verification step?"
echo "- Do top scoreboard items have active guardrails?"
echo "- Did I apply decision-framework.md to one meaningful decision?"
echo "- Did I run cognitive-bias-checks.md before finalizing hard calls?"

if [[ "$COMMIT" == true ]]; then
  echo "[6/6] Commit changes..."
  git commit -m "$COMMIT_MESSAGE"

  if [[ "$PUSH" == true ]]; then
    echo "Pushing to origin/main..."
    git push
  else
    echo "Commit created. Use git push when ready."
  fi
else
  echo "Prepared changes only (no commit)."
  echo "To finish: ./run-weekly-memory.sh --commit --push"
fi
