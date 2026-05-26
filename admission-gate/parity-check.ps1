# Cross-language parity test for the admission-gate scorer.
#
# Runs the PowerShell and Python scorers in --parity mode against the same
# fixture, compares per-id decisions, and exits non-zero if they disagree.
# This is the contract that keeps the two implementations honest: same
# fixture in, same per-item keep/reject out.
#
# Usage:
#   pwsh ./admission-gate/parity-check.ps1
#   pwsh ./admission-gate/parity-check.ps1 -Fixture admission-gate/fixtures/memories-v4.jsonl
#
# Exit codes: 0 ok, 2 fixture missing, 4 decisions diverge.

param(
  [string] $Fixture = "admission-gate/fixtures/memories-v4.jsonl",
  [string] $Store   = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
Set-Location $repoRoot

if (-not (Test-Path $Fixture)) {
  [Console]::Error.WriteLine("Fixture not found: $Fixture")
  exit 2
}

# Add a --parity mode to the PS scorer inline by reusing Score-Memory.
# Simpler: dot-source the scorer's scoring functions is heavy; instead we
# spawn two processes that each emit one JSON per item and diff the
# resulting maps. The Python side already has --parity. The PS side gets
# a parity helper here so we do not have to touch score-memory.ps1.
$psParity = Join-Path $scriptDir 'parity-emit.ps1'
if (-not (Test-Path $psParity)) {
  [Console]::Error.WriteLine("Missing parity-emit.ps1 next to parity-check.ps1")
  exit 2
}

Write-Host "Parity check: $Fixture"
if ($Store) { Write-Host "             store: $Store" }

# Prefer pwsh (cross-platform, what CI uses); fall back to Windows
# PowerShell when pwsh is not on PATH (local dev on Windows).
$psHost = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
if ($Store) {
  $psOut = & $psHost -NoProfile -File $psParity -Fixture $Fixture -Store $Store
} else {
  $psOut = & $psHost -NoProfile -File $psParity -Fixture $Fixture
}
if ($LASTEXITCODE -ne 0) {
  [Console]::Error.WriteLine("PS parity emitter failed (exit $LASTEXITCODE)")
  exit 2
}

# Prefer python (Linux CI); fall back to py launcher (Windows local).
$pyHost = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { 'py' }
if ($Store) {
  $pyOut = & $pyHost admission-gate/score_memory.py --parity --fixture $Fixture --store $Store
} else {
  $pyOut = & $pyHost admission-gate/score_memory.py --parity --fixture $Fixture
}
if ($LASTEXITCODE -ne 0) {
  [Console]::Error.WriteLine("Python parity emitter failed (exit $LASTEXITCODE)")
  exit 2
}

function Parse-Map([string[]]$lines) {
  $map = @{}
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $obj = $line | ConvertFrom-Json
    $map[$obj.id] = $obj.decision
  }
  return $map
}

$psMap = Parse-Map $psOut
$pyMap = Parse-Map $pyOut

if ($psMap.Count -ne $pyMap.Count) {
  [Console]::Error.WriteLine("Item count differs: ps=$($psMap.Count) py=$($pyMap.Count)")
  exit 4
}

$diffs = New-Object System.Collections.Generic.List[string]
foreach ($id in $psMap.Keys) {
  if (-not $pyMap.ContainsKey($id)) {
    $diffs.Add("$id : missing in python")
    continue
  }
  if ($psMap[$id] -ne $pyMap[$id]) {
    $diffs.Add("$id : ps=$($psMap[$id])  py=$($pyMap[$id])")
  }
}

if ($diffs.Count -gt 0) {
  Write-Host ""
  Write-Host "PARITY FAILURE: $($diffs.Count) item(s) disagree"
  foreach ($d in $diffs) { Write-Host "  $d" }
  exit 4
}

Write-Host "OK: $($psMap.Count) items, all decisions match across PS and Python."
exit 0
