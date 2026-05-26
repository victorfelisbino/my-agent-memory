#!/usr/bin/env bash
# Parity stub for generate-competence-map.ps1.
#
# Status: parity is roadmap Wave 2.5 follow-up. Today, the PowerShell version
# is the canonical implementation (matches the rest of the daily-driver
# scripts in this repo). If pwsh is on PATH we delegate to it; otherwise we
# print a clear pointer.
set -euo pipefail

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -File "$(dirname "$0")/generate-competence-map.ps1" "$@"
fi

cat >&2 <<'EOF'
generate-competence-map.sh: pwsh not found.

This script is currently a parity stub. The canonical implementation lives at
scripts/generate-competence-map.ps1 and runs on PowerShell 7+. Install pwsh
(https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
and re-run, or run the PowerShell version directly:

  pwsh ./scripts/generate-competence-map.ps1

A native bash port is tracked as a Wave 2.5 follow-up in docs/roadmap.md.
EOF
exit 1
