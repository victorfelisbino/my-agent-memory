#!/usr/bin/env bash
set -euo pipefail

TYPE=""
NOTE=""
DOMAIN="General"
TAGS=""
LOG_FILE="observations.jsonl"
NO_GATE=0

usage() {
  echo "Usage: capture-observation.sh --type <decision|blocker|progress|dead-end|insight> --note \"<text>\" [--domain General|Salesforce|MuleSoft] [--tags \"tag1,tag2\"] [--no-gate]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2;;
    --note) NOTE="$2"; shift 2;;
    --domain) DOMAIN="$2"; shift 2;;
    --tags) TAGS="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    --no-gate) NO_GATE=1; shift;;
    *) usage;;
  esac
done

[[ -z "$TYPE" || -z "$NOTE" ]] && usage

case "$TYPE" in
  decision|blocker|progress|dead-end|insight) ;;
  *) echo "Invalid --type: $TYPE"; usage;;
esac

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_personal-root.sh
source "$REPO_ROOT/_personal-root.sh"
PERSONAL_ROOT="$(get_personal_root "$REPO_ROOT")"
if [[ "$LOG_FILE" == /* ]]; then
  LOG_PATH="$LOG_FILE"
else
  LOG_PATH="$PERSONAL_ROOT/$LOG_FILE"
fi
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

TAGS_JSON="[]"
if [[ -n "$TAGS" ]]; then
  TAGS_JSON="[$(echo "$TAGS" | awk -F',' '{for(i=1;i<=NF;i++){gsub(/^ +| +$/,"",$i); printf "\"%s\"%s",$i,(i<NF?",":"")}}')]"
fi

NOTE_ESCAPED="$(printf '%s' "$NOTE" | sed 's/\\/\\\\/g; s/"/\\"/g')"

# Iter 13: admission-gate write-path integration. Score the candidate before
# appending; rejected items divert to observations.rejected.jsonl. Bypass via
# --no-gate or MEMORY_GATE=off.
GATE_OFF=$NO_GATE
[[ "${MEMORY_GATE:-}" == "off" ]] && GATE_OFF=1
SCORER="$REPO_ROOT/admission-gate/score_memory.py"
if [[ "$GATE_OFF" -eq 0 && -f "$SCORER" ]]; then
  PY=""
  if command -v python >/dev/null 2>&1; then PY=python
  elif command -v python3 >/dev/null 2>&1; then PY=python3
  fi
  if [[ -n "$PY" ]]; then
    CANDIDATE="$(printf '{"text":"%s"}' "$NOTE_ESCAPED")"
    DECISION_JSON="$(printf '%s' "$CANDIDATE" | "$PY" "$SCORER" --score-one 2>/dev/null || true)"
    DECISION="$(printf '%s' "$DECISION_JSON" | sed -n 's/.*"decision":[[:space:]]*"\([^"]*\)".*/\1/p')"
    if [[ "$DECISION" == "reject" ]]; then
      REASON="$(printf '%s' "$DECISION_JSON" | sed -n 's/.*"reason":[[:space:]]*"\([^"]*\)".*/\1/p')"
      REJECT_PATH="$PERSONAL_ROOT/observations.rejected.jsonl"
      printf '{"timestamp":"%s","type":"%s","domain":"%s","tags":%s,"note":"%s","reason":"%s"}\n' \
        "$TS" "$TYPE" "$DOMAIN" "$TAGS_JSON" "$NOTE_ESCAPED" "$REASON" >> "$REJECT_PATH"
      echo "[gate-reject] $DOMAIN :: $NOTE"
      echo "  reason: $REASON  (logged to $REJECT_PATH; rerun with --no-gate or MEMORY_GATE=off to bypass)"
      exit 3
    fi
  fi
fi

printf '{"timestamp":"%s","type":"%s","domain":"%s","tags":%s,"note":"%s"}\n' \
  "$TS" "$TYPE" "$DOMAIN" "$TAGS_JSON" "$NOTE_ESCAPED" >> "$LOG_PATH"

echo "[$TYPE] $DOMAIN :: $NOTE"
