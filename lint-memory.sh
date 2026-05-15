#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INCLUDE_CANONICAL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-canonical)
      INCLUDE_CANONICAL=1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

paths=("$ROOT_DIR/team-memory/inbox")
if [[ "$INCLUDE_CANONICAL" -eq 1 ]]; then
  paths+=("$ROOT_DIR/team-memory/canonical")
fi

issues=0
checked=0

check_file() {
  local f="$1"
  checked=$((checked + 1))

  local text
  text="$(cat "$f")"

  if ! grep -Eq '^##[[:space:]]+\[(P0|P1|P2)\]' "$f"; then
    echo "- [$f] Missing severity heading (## [P0|P1|P2] ...)."
    issues=$((issues + 1))
  fi

  local required=(
    'Domain:'
    'Scope:'
    'What failed:'
    'Guardrail to prevent recurrence:'
    'Evidence:'
    'Confidence:'
    'Last verified date:'
    'Owner:'
    'Date:'
  )

  for field in "${required[@]}"; do
    if ! grep -Fq "$field" "$f"; then
      echo "- [$f] Missing required field: $field"
      issues=$((issues + 1))
    fi
  done

  local conf
  conf="$(grep -Eio '^[[:space:]]*[-*]?[[:space:]]*confidence:[[:space:]]*(.*)$' "$f" | head -n 1 | sed -E 's/.*confidence:[[:space:]]*//I' | tr '[:upper:]' '[:lower:]')"
  if [[ -n "$conf" ]] && [[ "$conf" != "low" && "$conf" != "medium" && "$conf" != "high" ]]; then
    echo "- [$f] Invalid confidence value '$conf'. Allowed: low|medium|high."
    issues=$((issues + 1))
  fi

  local date_lines
  date_lines="$(grep -Ein '^[[:space:]]*[-*]?[[:space:]]*(last[[:space:]]*verified([[:space:]]*date)?|date|re-verify[[:space:]]*by)[[:space:]]*:' "$f" || true)"
  if [[ -n "$date_lines" ]]; then
    while IFS= read -r dl; do
      [[ -z "$dl" ]] && continue
      value="$(echo "$dl" | sed -E 's/^[0-9]+:[[:space:]]*[-*]?[[:space:]]*[^:]+:[[:space:]]*//')"
      value="$(echo "$value" | sed -E 's/[[:space:]]+$//')"
      if [[ -n "$value" ]] && ! echo "$value" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        echo "- [$f] Date fields must use YYYY-MM-DD (found '$value')."
        issues=$((issues + 1))
      fi
    done <<< "$date_lines"
  fi
}

for p in "${paths[@]}"; do
  [[ -d "$p" ]] || continue
  while IFS= read -r file; do
    [[ "$(basename "$file")" == "README.md" ]] && continue
    check_file "$file"
  done < <(find "$p" -type f -name '*.md')
done

echo "Files checked: $checked"
if [[ "$issues" -eq 0 ]]; then
  echo 'Memory lint passed.'
  exit 0
fi

echo "Memory lint found $issues issue(s)."
exit 1
