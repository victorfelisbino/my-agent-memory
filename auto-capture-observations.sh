#!/usr/bin/env bash
set -euo pipefail

SINCE_DAYS=14
MAX_PER_RUN=50
DRY_RUN="false"
LOG_FILE="observations.jsonl"
TRANSCRIPT_DIR=""
NO_GATE="false"

usage() {
  echo "Usage: auto-capture-observations.sh [--since-days N] [--max-per-run N] [--log-file FILE] [--transcript-dir DIR] [--dry-run] [--no-gate]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since-days) SINCE_DAYS="$2"; shift 2;;
    --max-per-run) MAX_PER_RUN="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    --transcript-dir) TRANSCRIPT_DIR="$2"; shift 2;;
    --dry-run) DRY_RUN="true"; shift;;
    --no-gate) NO_GATE="true"; shift;;
    -h|--help) usage;;
    *) usage;;
  esac
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 required for auto-capture-observations.sh"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_personal-root.sh
source "$REPO_ROOT/_personal-root.sh"
PERSONAL_ROOT="$(get_personal_root "$REPO_ROOT")"
if [[ "$LOG_FILE" == /* ]]; then
  LOG_PATH="$LOG_FILE"
else
  LOG_PATH="$PERSONAL_ROOT/$LOG_FILE"
fi

# Detect workspace storage root if not provided
if [[ -z "$TRANSCRIPT_DIR" ]]; then
  case "$(uname -s)" in
    Darwin) WS_ROOT="$HOME/Library/Application Support/Code/User/workspaceStorage";;
    Linux)  WS_ROOT="$HOME/.config/Code/User/workspaceStorage";;
    *)      echo "Unsupported OS for auto-detect; pass --transcript-dir"; exit 1;;
  esac
else
  WS_ROOT="$TRANSCRIPT_DIR"
fi

if [[ ! -d "$WS_ROOT" ]]; then
  echo "Workspace storage root not found: $WS_ROOT"
  exit 0
fi

if [[ "${MEMORY_GATE:-}" == "off" ]]; then
  NO_GATE="true"
fi
, repo_root, no_gate = sys.argv[1:9]
since_days = int(since_days); max_per_run = int(max_per_run)
dry_run = (dry_run == 'true')
no_gate = (no_gate == 'true')
scorer = os.path.join(repo_root, 'admission-gate', 'score_memory.py')
gate_on = (not no_gate) and os.path.isfile(scorer)
reject_path = os.path.join(os.path.dirname(log_path), 'observations.rejected.jsonllob, hashlib, datetime as dt, subprocess

ws_root, log_path, since_days, max_per_run, dry_run, explicit_dir = sys.argv[1:7]
since_days = int(since_days); max_per_run = int(max_per_run)
dry_run = (dry_run == 'true')
cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=since_days)

# Collect transcript dirs
dirs = []
if explicit_dir and os.path.isdir(explicit_dir):
    dirs.append(explicit_dir)
else:
    for d in glob.glob(os.path.join(ws_root, '*')):
        c = os.path.join(d, 'GitHub.copilot-chat', 'transcripts')
        if os.path.isdir(c):
            dirs.append(c)
if not dirs:
    print("No transcript directories found.")
    sys.exit(0)

patterns = [
    ('blocker',  re.compile(r'\b(error|failed|cannot|won\'t|stuck|broken|exception|traceback|undefined|null reference)\b', re.I), 'auto-blocker'),
    ('dead-end', re.compile(r'\b(reverted|rolled back|rollback|abandoned|gave up|backed out|didn\'t work|did not work)\b', re.I), 'auto-dead-end'),
    ('decision', re.compile(r'\b(let\'?s use|going with|chose|decided to|will use|switching to|adopt(ed|ing)?)\b', re.I), 'auto-decision'),
    ('insight',  re.compile(r'\b(turns out|learned|realized|gotcha|surprise|aha|note that|key insight|root cause)\b', re.I), 'auto-insight'),
    ('progress', re.compile(r'\b(shipped|merged|landed|implemented|fixed the|resolved the)\b', re.I), 'auto-progress'),
]

domain_keywords = [
    ('Salesforce', ['salesforce','apex','soql','sobject','lwc','sf cli','sfdx','gearset','profile','permission set','flow']),
    ('MuleSoft',   ['mulesoft','mule ','anypoint','raml','cloudhub','dataweave']),
]

def resolve_domain(text):
    low = text.lower()
    for dom, kws in domain_keywords:
        for k in kws:
            if k in low:
                return dom
    return 'General'

secret_patterns = [
    (re.compile(r'(?i)bearer\s+[A-Za-z0-9._\-]{20,}'), 'Bearer [REDACTED]'),
    (re.compile(r'eyJ[A-Za-z0-9._\-]{20,}'), '[REDACTED_JWT]'),
    (re.compile(r'00D[A-Za-z0-9]{12,18}![A-Za-z0-9._\-]+'), '[REDACTED_SF_SESSION]'),
    (re.compile(r'\b(?:sk|pk|rk)_(?:live|test)_[A-Za-z0-9]{16,}\b'), '[REDACTED_STRIPE_KEY]'),
    (re.compile(r'\bxox[bpasr]-[A-Za-z0-9-]{10,}\b'), '[REDACTED_SLACK_TOKEN]'),
    (re.compile(r'\bgh[pousr]_[A-Za-z0-9]{30,}\b'), '[REDACTED_GITHUB_TOKEN]'),
    (re.compile(r'\bAKIA[0-9A-Z]{16}\b'), '[REDACTED_AWS_KEY]'),
    (re.compile(r'(?i)(password|passwd|pwd|secret|api[_-]?key|token|auth[_-]?key)\s*[:=]\s*[\'"]?[^\s\'"]{6,}'), r'\1=[REDACTED]'),
    (re.compile(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'), '[REDACTED_EMAIL]'),
]

def scrub(text):
    for pat, rep in secret_patterns:
        text = pat.sub(rep, text)
    return text

def hash_key(t, note):
    s = f"{t}|{note.lower()[:120]}"
    return hashlib.sha1(s.encode('utf-8')).hexdigest()[:16]

existing = set()
if os.path.isfile(log_path):
    with open(log_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                o = json.loads(line)
                existing.add(hash_key(o.get('type',''), o.get('note','')))
            except Exception:
                continue

candidates = []
for d in set(dirs):
    for path in glob.glob(os.path.join(d, '*.jsonl')):
        mtime = dt.datetime.fromtimestamp(os.path.getmtime(path), dt.timezone.utc)
        if mtime < cutoff:
            continue
        try:
            with open(path, 'r', encoding='utf-8') as f:
                for line in f:
                    try:
                        obj = json.loads(line)
                    except Exception:
                        continue
                    t = obj.get('type','')
                    data = obj.get('data') or {}
                    content = data.get('content')
                    if not content or not isinstance(content, str):
                        continue
                    role = 'user' if t == 'user.message' else ('assistant' if t == 'assistant.message' else None)
                    if not role:
                        continue
                    if len(content) < 20 or len(content) > 1000:
                        continue
                    if content.count('`') > 6: continue
                    if content.lstrip().startswith('```'): continue
                    if content.count('|') > 4: continue

                    ts_raw = obj.get('timestamp')
                    ts = None
                    if ts_raw:
                        try:
                            ts = dt.datetime.fromisoformat(ts_raw.replace('Z','+00:00'))
                        except Exception:
                            ts = None
                    if ts is None:
                        ts = mtime
                    if ts < cutoff: continue

                    for ptype, prx, tag in patterns:
                        if prx.search(content):
                            sentences = re.split(r'(?<=[.!?])\s+', content)
                            sent = next((s for s in sentences if prx.search(s)), content)
                            sent = re.sub(r'\s+', ' ', sent).strip()
                            if len(sent) > 240:
                                sent = sent[:237] + '...'
                            sent = scrub(sent)
                            h = hash_key(ptype, sent)
                            if h in existing:
                                break
                            existing.add(h)
                            domain = resolve_domain(content)
                            candidates.append({
                                'timestamp': ts.isoformat(timespec='seconds'),
                                'type': ptype,
                                'domain': domain,
                                'tags': [tag, f'source:{role}'],
                                'note': sent,
                            })
                            break
        except Exception:
            continue

candidates.sort(key=lambda c: c['timestamp'], reverse=True)
candidates = candidates[:max_per_run]

if not candidates:
    print("No new observations to capture.")
def gate(note):
    # Returns (keep_bool, reason). When gate_on is False, always keep.
    if not gate_on:
        return True, ''
    try:
        proc = subprocess.run(
            [sys.executable, scorer, '--score-one'],
            input=json.dumps({'text': note}),
            capture_output=True, text=True, timeout=30,
        )
    except Exception:
        return True, ''
    if proc.returncode == 3:
        reason = ''
        try:
            reason = json.loads(proc.stdout).get('reason', '')
        except Exception:
            pass
        return False, reason
    return True, ''

kept = 0
rejected = 0
with open(log_path, 'a', encoding='utf-8') as f:
    for c in candidates:
        keep, reason = gate(c['note'])
        if keep:
            f.write(json.dumps(c, ensure_ascii=False) + '\n')
            kept += 1
        else:
            r = dict(c); r['reason'] = reason; r['source'] = 'auto-capture'
            with open(reject_path, 'a', encoding='utf-8') as rf:
                rf.write(json.dumps(r, ensure_ascii=False) + '\n')
            rejected += 1

if rejected:
    print(f"Appended {kept} auto-captured observation(s) to {log_path}; gate rejected {rejected} (see {reject_path})")
else:
    print(f"Appended {kept
        print(f"  [{c['type']}] {c['timestamp'][:10]} | {c['domain']} - {c['note']}")
    sys.exit(0)

with open(log_path, 'a', encoding='utf-8') as f:
    for c in candidates:
        f.write(json.dumps(c, ensure_ascii=False) + '\n')

print(f"Appended {len(candidates)} auto-captured observation(s) to {log_path}")
PY
