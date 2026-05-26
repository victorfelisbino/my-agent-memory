#!/usr/bin/env bash
# Parity stub for admission-gate/score-memory.ps1.
# Delegates to pwsh when available; otherwise prints install guidance and exits 1.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$here/score-memory.ps1" "$@"
fi

cat >&2 <<'MSG'
score-memory.sh requires pwsh to be on PATH.
A native bash port is a roadmap follow-up; see docs/roadmap.md.
Install pwsh: https://learn.microsoft.com/powershell/scripting/install/installing-powershell
MSG
exit 1
