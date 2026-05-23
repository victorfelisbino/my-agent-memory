#!/usr/bin/env bash
# Minimal mirror of loop.ps1 for macOS/Linux. Same commands, same file.
# Usage:
#   ./loop.sh idea    "text"
#   ./loop.sh start   "text"
#   ./loop.sh promise "text" --to NAME --by YYYY-MM-DD
#   ./loop.sh wait    "text" --on WHO
#   ./loop.sh done    "text"
#   ./loop.sh show
set -euo pipefail

action="${1:-}"; shift || true
text="${1:-}"; [ $# -gt 0 ] && shift || true
to=""; by=""; on=""
while [ $# -gt 0 ]; do
  case "$1" in
    --to) to="$2"; shift 2;;
    --by) by="$2"; shift 2;;
    --on) on="$2"; shift 2;;
    *) shift;;
  esac
done

root="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_personal-root.sh
source "$root/_personal-root.sh"
personal_root="$(get_personal_root "$root")"
board="$personal_root/open-loops.md"
today="$(date +%F)"

log_obs() {
  local type="$1" note="$2"
  if [ -x "$root/capture-observation.sh" ]; then
    "$root/capture-observation.sh" --type "$type" --note "$note" --domain General --tag open-loops --log-file "$personal_root/observations.jsonl" >/dev/null 2>&1 || true
  fi
}

case "$action" in
  show) cat "$board"; exit 0;;
  idea)    new="- [ ] $text  — added: $today"; section="## Active Ideas (cap: 7)"; log_obs insight  "idea: $text";;
  start)   new="- [ ] $text  — next: (write a verb)  — touched: $today"; section="## In-Flight (cap: 5)"; log_obs progress "started: $text";;
  promise) [ -n "$to" ] && [ -n "$by" ] || { echo "need --to and --by"; exit 2; }
           new="- [ ] $text  — to: $to  — by: $by"; section="## Promises"; log_obs decision "promised to $to by $by: $text";;
  wait)    [ -n "$on" ] || { echo "need --on"; exit 2; }
           new="- [ ] $text  — on: $on  — since: $today"; section="## Waiting On"; log_obs blocker "waiting on $on: $text";;
  done)    new="- [x] $text  — $today"; section="## Done this week"; log_obs progress "done: $text";;
  *) echo "usage: loop.sh {idea|start|promise|wait|done|show} ..."; exit 2;;
esac

# Insert after the section header's first item-or-blank slot. Replace first "_empty_" placeholder if present.
awk -v sec="$section" -v new="$new" '
  BEGIN { inserted=0; in_sec=0 }
  {
    if ($0 ~ "^"sec) { in_sec=1; print; next }
    if (in_sec && $0 ~ /^## / ) { if (!inserted) { print new; inserted=1 } in_sec=0 }
    if (in_sec && !inserted && $0 ~ /_empty_/) { print new; inserted=1; next }
    print
  }
  END { if (in_sec && !inserted) print new }
' "$board" > "$board.tmp" && mv "$board.tmp" "$board"

echo "[$action] ok — open-loops.md updated."
