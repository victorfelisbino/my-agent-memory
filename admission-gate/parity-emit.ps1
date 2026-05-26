# Parity emitter for the PowerShell scorer.
#
# Emits one JSON object per fixture item: {id, decision, total}. Used by
# parity-check.ps1 to diff PS vs Python decisions. Kept separate from
# score-memory.ps1 so the main scorer's surface stays focused on the
# baseline / unlabeled modes that CI consumes.
#
# Re-uses the scoring functions from score-memory.ps1 by dot-sourcing,
# but score-memory.ps1 is a script with side effects (Set-Location,
# Get-Content, summary printing), so dot-sourcing would execute it.
# Inline a thin re-implementation that calls into the same regex set
# would duplicate logic and drift. Instead, we shell out to the main
# scorer with a fixture-of-one and parse its per-item -Verbose output.
# That works but is brittle and slow.
#
# Simplest reliable contract: re-run the scoring logic here by reading
# the same fixture and emitting compact JSON. We import the scoring
# functions by reading score-memory.ps1 up to (but not including) the
# load/summarize section, evaluating only the function definitions and
# the helper arrays. The marker string we cut at is the line beginning
# with "# Load fixture, score, summarize.".

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

$scorerPath = Join-Path $scriptDir 'score-memory.ps1'
$raw = Get-Content $scorerPath -Raw

$marker = '# Load fixture, score, summarize.'
$idx = $raw.IndexOf($marker)
if ($idx -lt 0) {
  [Console]::Error.WriteLine("Could not find load/summarize marker in score-memory.ps1; parity emitter needs an update.")
  exit 2
}

# Cut the script at the marker and evaluate only the function/array
# definitions. The `param(...)` block at the top of score-memory.ps1
# would overwrite our $Fixture variable back to its default when
# evaluated via Invoke-Expression, so save and restore it.
$prelude = $raw.Substring(0, $idx)
$savedFixture = $Fixture
$savedStore   = $Store
Invoke-Expression $prelude
$Fixture = $savedFixture
$Store   = $savedStore

# Re-load store claims now that prelude functions are defined and that
# $Store has been restored to the caller value.
$script:StoreClaims = Load-StoreClaims $Store

$lines = Get-Content $Fixture -Encoding UTF8 | Where-Object { $_.Trim() -ne '' -and -not $_.TrimStart().StartsWith('#') }
foreach ($line in $lines) {
  $rec = $null
  try { $rec = $line | ConvertFrom-Json } catch {
    [Console]::Error.WriteLine("Malformed JSONL line: $line")
    exit 2
  }
  $s = Score-Memory $rec.text
  $payload = [pscustomobject]@{
    id       = $rec.id
    decision = $s.decision
    total    = [math]::Round($s.total, 2)
  }
  $payload | ConvertTo-Json -Compress
}

exit 0
