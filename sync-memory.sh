#!/usr/bin/env bash
# Minimal mirror of sync-memory.ps1 for macOS/Linux machines.
# Pulls, captures from local Copilot transcripts with machine+workspace tags,
# regenerates active-threads.md, optionally commits and pushes.
#
# Usage:
#   ./sync-memory.sh                # pull + capture + regenerate (no commit)
#   ./sync-memory.sh --commit       # also commit
#   ./sync-memory.sh --commit --push
set -euo pipefail

since_days=14
max_per_ws=25
do_pull=1
do_commit=0
do_push=0

while [ $# -gt 0 ]; do
  case "$1" in
    --no-pull) do_pull=0; shift;;
    --commit)  do_commit=1; shift;;
    --push)    do_push=1; shift;;
    --since)   since_days="$2"; shift 2;;
    *) shift;;
  esac
done

root="$(cd "$(dirname "$0")" && pwd)"
cd "$root"
# shellcheck source=_personal-root.sh
source "$root/_personal-root.sh"
personal_root="$(get_personal_root "$root")"
personal_is_repo=0
[ -d "$personal_root/.git" ] && personal_is_repo=1

machine="$(hostname | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9._-' '-')"

echo "[sync-memory] framework: $root"
echo "[sync-memory] personal : $personal_root$( [ "$personal_is_repo" = 0 ] && echo ' (NOT a git repo)' )"

# Detect VS Code workspaceStorage root by OS
case "$(uname)" in
  Darwin) ws_root="$HOME/Library/Application Support/Code/User/workspaceStorage";;
  Linux)  ws_root="$HOME/.config/Code/User/workspaceStorage";;
  *)      ws_root="${APPDATA:-$HOME}/Code/User/workspaceStorage";;
esac

if [ "$do_pull" -eq 1 ]; then
  if [ "$personal_is_repo" = 1 ]; then
    echo "[sync-memory] git pull (personal repo)..."
    git -C "$personal_root" pull --no-edit || { echo 'git pull failed'; exit 1; }
  else
    echo "[sync-memory] personal dir is not a git repo - skipping pull"
  fi
fi

if [ ! -d "$ws_root" ]; then
  echo "[sync-memory] workspaceStorage not found at $ws_root"
  exit 0
fi

count=0
for ws_dir in "$ws_root"/*/; do
  tx="$ws_dir/GitHub.copilot-chat/transcripts"
  [ -d "$tx" ] || continue
  name="$(basename "$ws_dir" | cut -c1-12)"
  if [ -f "$ws_dir/workspace.json" ] && command -v python3 >/dev/null 2>&1; then
    decoded="$(python3 -c "import json,urllib.parse,sys,os; d=json.load(open('$ws_dir/workspace.json')); f=d.get('folder',''); f=urllib.parse.unquote(f).replace('file://',''); print(os.path.basename(f.rstrip('/')))" 2>/dev/null || true)"
    [ -n "$decoded" ] && name="$(echo "$decoded" | tr -c 'A-Za-z0-9._-' '-' | tr '[:upper:]' '[:lower:]')"
  fi
  echo "[sync-memory] capturing $name ..."
  if [ -x "$root/auto-capture-observations.sh" ]; then
    "$root/auto-capture-observations.sh" --transcript-dir "$tx" --since-days "$since_days" --max-per-run "$max_per_ws" --log-file "$personal_root/observations.jsonl" --extra-tag "machine:$machine" --extra-tag "workspace:$name" || true
  fi
  count=$((count+1))
done
echo "[sync-memory] processed $count workspace(s) on $machine"

# Build active-threads.md (simple version: group last $since_days observations by workspace tag)
python3 - "$since_days" "$personal_root" <<'PY'
import json, sys, os, datetime, collections
since_days = int(sys.argv[1])
personal_root = sys.argv[2]
cutoff = datetime.datetime.now(datetime.timezone.utc).timestamp() - since_days*86400
log = os.path.join(personal_root, 'observations.jsonl')
entries = []
if os.path.exists(log):
    for line in open(log, encoding='utf-8'):
        line=line.strip()
        if not line: continue
        try: o = json.loads(line)
        except: continue
        ts_s = o.get('timestamp','')
        try:
            ts = datetime.datetime.fromisoformat(ts_s.replace('Z','+00:00'))
            if ts.tzinfo is None: ts = ts.replace(tzinfo=datetime.timezone.utc)
        except: continue
        if ts.timestamp() < cutoff: continue
        tags = o.get('tags') or []
        machine=next((t[8:] for t in tags if t.startswith('machine:')), '?')
        workspace=next((t[10:] for t in tags if t.startswith('workspace:')), '(unattributed)')
        entries.append((ts, o.get('type',''), machine, workspace, (o.get('note','') or '').strip()))

groups = collections.defaultdict(list)
for e in entries: groups[e[3]].append(e)
ordered = sorted(groups.items(), key=lambda kv: max(x[0] for x in kv[1]), reverse=True)

out=[]
out.append('# Active Threads (cross-machine)')
out.append('')
out.append(f'Updated: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
out.append(f'Window: last {since_days} days')
out.append(f'Total observations in window: {len(entries)}')
out.append(f'Workspaces with activity: {len(ordered)}')
machines = sorted({e[2] for e in entries})
out.append('Machines seen: ' + ', '.join(machines))
out.append('')
if not ordered:
    out.append('_No attributed activity yet._')
else:
    for ws, items in ordered:
        items.sort(key=lambda x: x[0], reverse=True)
        latest = items[0][0].strftime('%Y-%m-%d %H:%M')
        mach = ', '.join(sorted({i[2] for i in items}))
        out.append(f'## {ws}')
        out.append(f'- Last activity: {latest} on {mach}')
        out.append(f'- Observations in window: {len(items)}')
        out.append('')
        out.append('### Recent signals')
        for ts, typ, m, _, note in items[:6]:
            if len(note) > 160: note = note[:157] + '...'
            out.append(f'- {ts.strftime("%Y-%m-%d")} [{typ}] ({m}) {note}')
        out.append('')
open(os.path.join(personal_root, 'active-threads.md'),'w',encoding='utf-8').write('\n'.join(out))
print(f'[sync-memory] wrote active-threads.md ({len(ordered)} workspace group(s))')
PY

if [ "$do_commit" -eq 1 ]; then
  if [ "$personal_is_repo" = 0 ]; then
    echo "[sync-memory] personal dir is not a git repo - skipping commit/push"
  else
    git -C "$personal_root" add observations.jsonl active-threads.md 2>/dev/null || true
    if git -C "$personal_root" diff --cached --quiet; then
      echo "[sync-memory] no changes to commit"
    else
      git -C "$personal_root" commit -m "memory: sync from $machine"
      if [ "$do_push" -eq 1 ]; then
        git -C "$personal_root" push || (git -C "$personal_root" pull --no-edit && git -C "$personal_root" push)
      fi
    fi
  fi
fi
echo "[sync-memory] done. Open $personal_root/active-threads.md."
