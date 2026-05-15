#!/usr/bin/env bash
set -euo pipefail

DOMAIN="Auto"
TASK=""
TOP=10
OUTPUT_FILE="active-memory-brief.md"
PREFLIGHT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --task)
      TASK="$2"
      shift 2
      ;;
    --top)
      TOP="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --preflight)
      PREFLIGHT=1
      shift
      ;;
    *)
      echo "Unknown arg: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$TASK" ]]; then
  echo "--task is required"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_PATH="$ROOT_DIR/$OUTPUT_FILE"

detect_domain() {
  local task_lower
  task_lower="$(echo "$1" | tr '[:upper:]' '[:lower:]')"

  local sf=0
  local mule=0

  for k in salesforce apex soql sobject lwc 'connected app' sfdc 'sf cli' 'sf org'; do
    if echo "$task_lower" | grep -q "$k"; then sf=$((sf + 1)); fi
  done

  for k in mulesoft mule anypoint raml 'mule app' 'mule flow' exchange cloudhub; do
    if echo "$task_lower" | grep -q "$k"; then mule=$((mule + 1)); fi
  done

  if [[ "$sf" -gt "$mule" && "$sf" -gt 0 ]]; then
    echo "Salesforce"
    return
  fi

  if [[ "$mule" -gt "$sf" && "$mule" -gt 0 ]]; then
    echo "MuleSoft"
    return
  fi

  echo "General"
}

freshness_score() {
  local file="$1"
  local now
  now="$(date +%s)"

  local modified=0
  if stat -c %Y "$file" >/dev/null 2>&1; then
    modified="$(stat -c %Y "$file")"
  else
    modified="$(stat -f %m "$file")"
  fi

  local age_days=$(((now - modified) / 86400))

  if [[ "$age_days" -le 7 ]]; then
    echo 3
  elif [[ "$age_days" -le 30 ]]; then
    echo 2
  elif [[ "$age_days" -le 90 ]]; then
    echo 1
  else
    echo 0
  fi
}

date_to_epoch() {
  local d="$1"
  if date -d "$d" +%s >/dev/null 2>&1; then
    date -d "$d" +%s
    return
  fi

  if date -j -f "%Y-%m-%d" "$d" +%s >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$d" +%s
    return
  fi

  echo ""
}

confidence_score() {
  local file="$1"
  local conf
  conf="$(grep -Eio '^[[:space:]]*[-*]?[[:space:]]*confidence:[[:space:]]*(low|medium|high)\b' "$file" | head -n 1 | sed -E 's/.*confidence:[[:space:]]*//I' | tr '[:upper:]' '[:lower:]')"

  case "$conf" in
    high) echo 2 ;;
    medium) echo 1 ;;
    low) echo -1 ;;
    *) echo 0 ;;
  esac
}

verification_score() {
  local file="$1"
  local d
  d="$(grep -Eio '^[[:space:]]*[-*]?[[:space:]]*last[[:space:]]*verified([[:space:]]*date)?[[:space:]]*:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}\b' "$file" | head -n 1 | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)"

  if [[ -z "$d" ]]; then
    echo -1
    return
  fi

  local verified_epoch
  verified_epoch="$(date_to_epoch "$d")"
  if [[ -z "$verified_epoch" ]]; then
    echo -1
    return
  fi

  local now
  now="$(date +%s)"
  local age_days=$(((now - verified_epoch) / 86400))

  if [[ "$age_days" -le 30 ]]; then
    echo 2
  elif [[ "$age_days" -le 90 ]]; then
    echo 1
  elif [[ "$age_days" -le 180 ]]; then
    echo 0
  else
    echo -1
  fi
}

normalize_words() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 -]/ /g' | tr ' ' '\n' \
    | awk 'length($0)>=4' \
    | grep -Ev '^(the|and|for|with|from|that|this|your|about|into|will|have|need|using|when|what|where|how|why|can|could|should|would|make|more|less|then|than|also|just|task|work|project|create|build|setup|set|get|use|api|app|access|domain)$' \
    | awk '!seen[$0]++'
}

mapfile -t KEYWORDS < <(normalize_words "$TASK")

RESOLVED_DOMAIN="$DOMAIN"
if [[ "$DOMAIN" == "Auto" ]]; then
  RESOLVED_DOMAIN="$(detect_domain "$TASK")"
fi

candidate_files=()
while IFS= read -r f; do candidate_files+=("$f"); done < <(find "$ROOT_DIR" -maxdepth 1 -name '*.md' ! -name 'memory-scoreboard.md' ! -name 'memory-top-patterns.md' ! -name "$OUTPUT_FILE" -type f)
if [[ -d "$ROOT_DIR/domains/general" ]]; then
  while IFS= read -r f; do candidate_files+=("$f"); done < <(find "$ROOT_DIR/domains/general" -maxdepth 1 -name '*.md' -type f)
fi
DOMAIN_LOWER="$(echo "$RESOLVED_DOMAIN" | tr '[:upper:]' '[:lower:]')"
if [[ -d "$ROOT_DIR/domains/$DOMAIN_LOWER" ]]; then
  while IFS= read -r f; do candidate_files+=("$f"); done < <(find "$ROOT_DIR/domains/$DOMAIN_LOWER" -maxdepth 1 -name '*.md' -type f)
fi

TMP="$(mktemp)"
: > "$TMP"

score_line() {
  local line="$1"
  local task_lower
  task_lower="$(echo "$TASK" | tr '[:upper:]' '[:lower:]')"
  local lower
  lower="$(echo "$line" | tr '[:upper:]' '[:lower:]')"

  local score=0

  for k in "${KEYWORDS[@]:-}"; do
    [[ -z "$k" ]] && continue
    if echo "$lower" | grep -q "$k"; then
      score=$((score + 2))
    fi
  done

  if echo "$line" | grep -Eq '^#{1,3}[[:space:]]'; then
    score=$((score + 1))
  fi

  if echo "$lower" | grep -Eq 'guardrail|risk|evidence|checklist|verify|oauth|token|auth|deploy|permission'; then
    score=$((score + 1))
  fi

  if echo "$task_lower" | grep -q 'salesforce' && echo "$lower" | grep -Eq 'salesforce|sf '; then
    score=$((score + 2))
  fi

  if [[ "$RESOLVED_DOMAIN" == "Salesforce" ]] && echo "$lower" | grep -Eq 'salesforce|sf |oauth|token|connected app|permission set'; then
    score=$((score + 1))
  fi

  if [[ "$RESOLVED_DOMAIN" == "MuleSoft" ]] && echo "$lower" | grep -Eq 'mulesoft|anypoint|raml|cloudhub|exchange'; then
    score=$((score + 1))
  fi

  echo "$score"
}

for file in "${candidate_files[@]}"; do
  rel="${file#$ROOT_DIR/}"
  fresh="$(freshness_score "$file")"
  conf="$(confidence_score "$file")"
  verify="$(verification_score "$file")"
  line_num=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    [[ -z "${line// }" ]] && continue

    base="$(score_line "$line")"
    total=$((base + fresh + conf + verify))
    if [[ "$total" -gt 0 ]] && ! echo "$line" | grep -Eq 'summon-memory\.(ps1|sh)'; then
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$total" "$base" "$fresh" "$conf" "$verify" "$rel" "$line_num" "$(echo "$line" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')" >> "$TMP"
    fi
  done < "$file"
done

NOW="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo '# Active Memory Brief'
  echo
  echo "Updated: $NOW"
  echo "Domain: $RESOLVED_DOMAIN"
  echo "Domain selection: $DOMAIN"
  echo "Task: $TASK"
  echo 'Scoring: total = relevance + freshness + confidence + verification-freshness'
  echo 'Confidence score: high=+2, medium=+1, low=-1, missing=0'
  echo 'Verification score: <=30d=+2, <=90d=+1, <=180d=0, stale/missing=-1'
  echo
  echo '## Suggested snippets'
  echo

  if [[ ! -s "$TMP" ]]; then
    echo '- No strong matches found. Add a new note for this scenario and rerun.'
  else
    sort -t $'\t' -k1,1nr -k5,5nr -k3,3nr -k6,6 "$TMP" | head -n "$TOP" | while IFS=$'\t' read -r total base fresh conf verify rel line text; do
      echo "- [$total = $base relevance + $fresh freshness + $conf confidence + $verify verification] $rel:$line - $text"
    done
  fi

  echo
  echo '## Usage'
  echo
  echo 'Copy this brief into your next Copilot prompt to force high-signal context.'
} > "$OUTPUT_PATH"

rm -f "$TMP"

echo "Updated: $OUTPUT_PATH"
echo "Files scanned: ${#candidate_files[@]}"
echo "Keywords: ${KEYWORDS[*]:-none}"
echo "Resolved domain: $RESOLVED_DOMAIN"

if [[ "$PREFLIGHT" -eq 1 ]]; then
  echo
  echo '----- COPILOT PREFLIGHT PROMPT -----'
  echo "Domain: $RESOLVED_DOMAIN"
  echo "Task: $TASK"
  echo
  echo 'Use this memory brief as highest-priority context:'
  echo
  cat "$OUTPUT_PATH"
  echo
  echo 'Instructions:'
  echo '- Prefer commands and guardrails from the brief when they fit.'
  echo '- If required values are org/project-specific, ask for them explicitly.'
  echo '- If memory conflicts with current codebase reality, trust current evidence and state the mismatch.'
  echo '----- END PREFLIGHT PROMPT -----'
fi