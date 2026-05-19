#!/usr/bin/env bash
set -euo pipefail

TYPE=""
NOTE=""
DOMAIN="General"
TAGS=""
LOG_FILE="observations.jsonl"

usage() {
  echo "Usage: capture-observation.sh --type <decision|blocker|progress|dead-end|insight> --note \"<text>\" [--domain General|Salesforce|MuleSoft] [--tags \"tag1,tag2\"]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2;;
    --note) NOTE="$2"; shift 2;;
    --domain) DOMAIN="$2"; shift 2;;
    --tags) TAGS="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    *) usage;;
  esac
done

[[ -z "$TYPE" || -z "$NOTE" ]] && usage

case "$TYPE" in
  decision|blocker|progress|dead-end|insight) ;;
  *) echo "Invalid --type: $TYPE"; usage;;
esac

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_PATH="$REPO_ROOT/$LOG_FILE"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

TAGS_JSON="[]"
if [[ -n "$TAGS" ]]; then
  TAGS_JSON="[$(echo "$TAGS" | awk -F',' '{for(i=1;i<=NF;i++){gsub(/^ +| +$/,"",$i); printf "\"%s\"%s",$i,(i<NF?",":"")}}')]"
fi

NOTE_ESCAPED="$(printf '%s' "$NOTE" | sed 's/\\/\\\\/g; s/"/\\"/g')"

printf '{"timestamp":"%s","type":"%s","domain":"%s","tags":%s,"note":"%s"}\n' \
  "$TS" "$TYPE" "$DOMAIN" "$TAGS_JSON" "$NOTE_ESCAPED" >> "$LOG_PATH"

echo "[$TYPE] $DOMAIN :: $NOTE"
