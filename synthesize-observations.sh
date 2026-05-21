#!/usr/bin/env bash
set -euo pipefail

DAYS=7
LOG_FILE="observations.jsonl"
OUTPUT_FILE="status-update.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    --output) OUTPUT_FILE="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_PATH="$REPO_ROOT/$LOG_FILE"
OUT_PATH="$REPO_ROOT/$OUTPUT_FILE"

if [[ ! -f "$LOG_PATH" ]]; then
  echo "No observations log at $LOG_PATH"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 required for synthesize-observations.sh"
  exit 1
fi

python3 - "$LOG_PATH" "$OUT_PATH" "$DAYS" <<'PY'
import json, sys, datetime as dt
log_path, out_path, days = sys.argv[1], sys.argv[2], int(sys.argv[3])
cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=days)
entries = []
with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            o = json.loads(line)
            ts = dt.datetime.fromisoformat(o['timestamp'].replace('Z','+00:00'))
            if ts >= cutoff:
                entries.append((ts, o))
        except Exception:
            continue
entries.sort(key=lambda x: x[0], reverse=True)
order = ['decision','blocker','dead-end','progress','insight']
out = []
out.append('# Status Update')
out.append('')
out.append(f'Window: last {days} days')
out.append(f'Generated: {dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
out.append(f'Observations: {len(entries)}')
out.append('')
if not entries:
    out.append('No observations captured in this window.')
else:
    for t in order:
        group = [e for e in entries if e[1].get('type') == t]
        if not group:
            continue
        out.append(f'## {t.upper()} ({len(group)})')
        out.append('')
        for ts, o in group:
            tags = o.get('tags') or []
            tagstr = f' [{", ".join(tags)}]' if tags else ''
            out.append(f'- {ts.strftime("%Y-%m-%d")} | {o.get("domain","General")}{tagstr} - {o.get("note","")}')
        out.append('')
    by_domain = {}
    for _, o in entries:
        d = o.get('domain','General')
        by_domain[d] = by_domain.get(d, 0) + 1
    out.append('## By domain')
    out.append('')
    for d, c in sorted(by_domain.items(), key=lambda x: -x[1]):
        out.append(f'- {d}: {c}')
    out.append('')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(out))
print(f'Wrote {out_path} with {len(entries)} observations')
PY
