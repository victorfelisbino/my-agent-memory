<#
.SYNOPSIS
  Run the admission-gate baseline scorer over a labeled memory fixture.

.DESCRIPTION
  Reads a JSONL fixture (one memory per line: id, label, category, text)
  and applies a small set of stub heuristic rules across four dimensions
  from the Wave 3 spec: reusability, atomicity, novelty (stub), actionability.
  Emits a per-memory decision (keep|reject + reason) and a summary block:
  total, predicted-keep, predicted-reject, accuracy, junk-recall, good-recall.

  THIS SCORER IS A BASELINE STUB. The point of v1 is the measurement loop,
  not the rules. The kill switch for Wave 3 fires when accuracy on a 100-item
  test set cannot beat random (50/50); today we have 20 items and stub rules,
  so treat the numbers as a starting baseline, not a claim.

.NOTES
  Run from repo root:  pwsh ./admission-gate/score-memory.ps1
  Add -Fixture <path>  to score a different JSONL file.
  Add -Verbose         to print per-memory decisions.
  Add -FailUnder <pct> to exit non-zero if accuracy < pct (CI gate).
  Exit codes: 0 ok, 2 fixture missing/malformed, 3 accuracy below threshold.
#>
param(
  [string] $Fixture   = "admission-gate/fixtures/memories-v1.jsonl",
  [switch] $Verbose,
  [int]    $FailUnder = 0
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
Set-Location $repoRoot

if (-not (Test-Path $Fixture)) {
  [Console]::Error.WriteLine("Fixture not found: $Fixture")
  exit 2
}

# ---------------------------------------------------------------------------
# Baseline rules (v1). Each returns a score in [-1, +1]. Sum maps to keep/reject.
# Positive = looks like a keepable memory. Negative = looks like junk.
# ---------------------------------------------------------------------------

# Reusability: penalize project/file/person/time specifics that won't generalize.
$reusabilityNegativePatterns = @(
  '\b(today|yesterday|tomorrow|just now)\b',
  '\b(at|on)\s+\d{1,2}[:.]\d{2}\b',
  '\b20\d{2}-\d{2}-\d{2}\b',
  '\b(office-pc|workstation|laptop-\w+)\b',
  '\b(line \d+|src/|repo|branch|feature/|sprint-?\d+)\b',
  '\b(named|aged?\s+\d+|years old|lives in)\b',
  '\bclient\b|\bacme\b|\bcustomer-\w+\b'
)

function Score-Reusability([string]$t) {
  $hits = 0
  foreach ($p in $reusabilityNegativePatterns) {
    if ($t -match $p) { $hits++ }
  }
  if ($hits -eq 0) { return  0.5 }
  if ($hits -eq 1) { return -0.3 }
  return -1.0
}

# Atomicity: penalize very long memories and contradictory-shape claims.
function Score-Atomicity([string]$t) {
  $score = 0.5
  if ($t.Length -gt 240) { $score -= 0.5 }
  # Contradiction shape: "always X ... never X" / "do X ... don't X" in one line.
  if ($t -match '\balways\b.*\bnever\b' -or $t -match '\bnever\b.*\balways\b') {
    $score -= 1.0
  }
  return $score
}

# Novelty: stubbed (no memory store wired in yet). Neutral so it does not
# bias the baseline. Hooks into the future store check.
function Score-Novelty([string]$t) {
  return 0.0
}

# Actionability: reward concrete imperatives + criteria; penalize vague filler.
$actionableVerbs = @('always','never','prefer','use','check','run','add','set','avoid','verify','ensure','promote','request','require')
$vagueFillers    = @('matters','should care','is important','quality','best practice','various','generally','sometimes')

function Score-Actionability([string]$t) {
  $score = 0.0
  $lc = $t.ToLowerInvariant()
  foreach ($v in $actionableVerbs)  { if ($lc -match "\b$v\b") { $score += 0.25 } }
  foreach ($f in $vagueFillers)     { if ($lc -match "\b$([regex]::Escape($f))\b") { $score -= 0.5 } }
  # Tautology shape: "if X then X" with same predicate echoed.
  if ($lc -match '\bif\s+.+\bthen\b.+\b(is|returns)\b') { $score -= 0.5 }
  # Self-referential filler.
  if ($lc -match '\bagent\b.*\b(answered|responded|said)\b') { $score -= 0.75 }
  # World noise (weather / wifi / generic environment statements).
  if ($lc -match '\b(sunny|raining|wifi|weather)\b') { $score -= 1.0 }
  # Cap.
  if ($score -gt  1.0) { $score =  1.0 }
  if ($score -lt -1.0) { $score = -1.0 }
  return $score
}

function Score-Memory([string]$text) {
  $r = Score-Reusability   $text
  $a = Score-Atomicity     $text
  $n = Score-Novelty       $text
  $c = Score-Actionability $text
  $total = $r + $a + $n + $c
  $decision = if ($total -ge 0) { 'keep' } else { 'reject' }
  $reason = @()
  if ($r -lt 0) { $reason += "reusability=$r" }
  if ($a -lt 0) { $reason += "atomicity=$a" }
  if ($c -lt 0) { $reason += "actionability=$c" }
  return [pscustomobject]@{
    reusability   = $r
    atomicity     = $a
    novelty       = $n
    actionability = $c
    total         = $total
    decision      = $decision
    reason        = ($reason -join '; ')
  }
}

# ---------------------------------------------------------------------------
# Load fixture, score, summarize.
# ---------------------------------------------------------------------------
$lines = Get-Content $Fixture -Encoding UTF8 | Where-Object { $_.Trim() -ne '' -and -not $_.TrimStart().StartsWith('#') }
$total = 0
$correct = 0
$truePositive  = 0  # keep predicted as keep
$falsePositive = 0  # reject predicted as keep
$trueNegative  = 0  # reject predicted as reject
$falseNegative = 0  # keep predicted as reject

$detailed = New-Object System.Collections.Generic.List[object]

foreach ($line in $lines) {
  $rec = $null
  try { $rec = $line | ConvertFrom-Json } catch {
    [Console]::Error.WriteLine("Malformed JSONL line: $line")
    exit 2
  }
  $s = Score-Memory $rec.text
  $total++
  $matched = $s.decision -eq $rec.label
  if ($matched) { $correct++ }
  if ($rec.label -eq 'keep'   -and $s.decision -eq 'keep')   { $truePositive++ }
  if ($rec.label -eq 'reject' -and $s.decision -eq 'keep')   { $falsePositive++ }
  if ($rec.label -eq 'reject' -and $s.decision -eq 'reject') { $trueNegative++ }
  if ($rec.label -eq 'keep'   -and $s.decision -eq 'reject') { $falseNegative++ }

  $detailed.Add([pscustomobject]@{
    id        = $rec.id
    label     = $rec.label
    decision  = $s.decision
    match     = if ($matched) { 'ok' } else { 'MISS' }
    total     = [math]::Round($s.total, 2)
    category  = $rec.category
    reason    = $s.reason
  })
}

if ($Verbose) {
  $detailed | Format-Table -AutoSize | Out-String | Write-Host
}

$accuracy   = if ($total -gt 0) { [math]::Round(100.0 * $correct       / $total, 1) } else { 0 }
$junkRecall = if (($trueNegative + $falsePositive) -gt 0) { [math]::Round(100.0 * $trueNegative / ($trueNegative + $falsePositive), 1) } else { 0 }
$goodRecall = if (($truePositive + $falseNegative) -gt 0) { [math]::Round(100.0 * $truePositive / ($truePositive + $falseNegative), 1) } else { 0 }

Write-Host ""
Write-Host "Admission-gate baseline (v1 stub rules)"
Write-Host "  fixture       : $Fixture"
Write-Host "  total         : $total"
Write-Host "  accuracy      : $accuracy%   (random baseline: 50.0%)"
Write-Host "  junk recall   : $junkRecall%   (Wave 3 exit: >= 80%)"
Write-Host "  good recall   : $goodRecall%   (Wave 3 exit: >= 80%)"
Write-Host "  confusion     : TP=$truePositive  TN=$trueNegative  FP=$falsePositive  FN=$falseNegative"
Write-Host ""

if ($FailUnder -gt 0 -and $accuracy -lt $FailUnder) {
  [Console]::Error.WriteLine("Accuracy $accuracy% below required $FailUnder%")
  exit 3
}

exit 0
