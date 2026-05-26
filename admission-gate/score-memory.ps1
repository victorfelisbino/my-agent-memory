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
  [string] $Fixture    = "admission-gate/fixtures/memories-v4.jsonl",
  [switch] $Verbose,
  [int]    $FailUnder  = 0,
  [switch] $Unlabeled,
  [int]    $ShowWorst  = 15
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
# Note: bare technical vocabulary like "branch" / "repo" / "src" is fine -- it
# appears in legitimate reusable memories ("never close a defect without branch
# diff + deploy report"). What we want to flag is *concrete instances*: a
# specific branch name, a specific line number, a specific file path, a
# specific sprint, a named client.
$reusabilityNegativePatterns = @(
  '\b(today|yesterday|tomorrow|just now)\b',
  '\b(at|on)\s+\d{1,2}[:.]\d{2}\b',
  '\b20\d{2}-\d{2}-\d{2}\b',
  '\b(office-pc|workstation|laptop-\w+)\b',
  '\bline\s+\d+\b',                       # "line 42"
  '\bsrc/[a-zA-Z0-9_./-]+',               # concrete src/ path
  '\bfeature/[a-zA-Z0-9._-]+',            # named feature branch
  '\bsprint-?\d+\b',                      # specific sprint number
  '\b(named|aged?\s+\d+|years old|lives in)\b',
  '\bacme\b|\bcustomer-\w+\b'             # named client
)

function Score-Reusability([string]$t) {
  $hits = 0
  foreach ($p in $reusabilityNegativePatterns) {
    if ($t -match $p) { $hits++ }
  }
  # Lower baseline reward (was 0.5) so vague memories with no positive signal
  # can dip below zero on actionability alone. Keeps still score well clear of
  # the threshold because they pick up actionability bonuses too.
  if ($hits -eq 0) { return  0.3 }
  if ($hits -eq 1) { return -0.3 }
  return -1.0
}

# Atomicity: penalize very long memories and contradictory-shape claims.
#
# Contradiction detection (iter 3): the bare regex `\balways\b.*\bnever\b` was
# too aggressive because "Always use Permission Sets; never use Profiles" is a
# legitimate dual-rule memory, not a contradiction. We now extract the first
# 1-2 content words after each marker (skipping stopwords + the common verb
# "use") and only flag when the resulting phrases overlap. "Always use tabs ...
# never use tabs" -> ("tabs") vs ("tabs") -> contradiction. "Always use
# Permission Sets ... never use Profiles" -> ("permission","sets") vs
# ("profiles") -> not a contradiction.
$contradictionStopwords = @(
  'the','a','an','some','any','to','for','on','in','of','and','or','but',
  'with','that','it','its','this','these','those','your','their','my','our',
  'use','do','be','have','make','take','get','give','call'
)

function Get-ContradictionPhrase([string]$lcText, [string]$marker) {
  if ($lcText -notmatch "\b$marker\b\s+([a-z0-9_/'-]+(?:\s+[a-z0-9_/'-]+){0,5})") { return '' }
  $words = $Matches[1] -split '\s+' |
    Where-Object { $_.Length -gt 1 -and ($contradictionStopwords -notcontains $_) } |
    Select-Object -First 2
  return (($words -join ' ').Trim())
}

function Test-Contradiction([string]$t) {
  $lc = $t.ToLowerInvariant()
  if (-not ($lc -match '\balways\b' -and $lc -match '\bnever\b')) { return $false }
  $a = Get-ContradictionPhrase $lc 'always'
  $n = Get-ContradictionPhrase $lc 'never'
  return ($a -ne '' -and $a -eq $n)
}

function Score-Atomicity([string]$t) {
  $score = 0.3
  if ($t.Length -gt 240) { $score -= 0.5 }
  if (Test-Contradiction $t) { $score -= 1.5 }
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

# Tech/control-flow allowlist for the named-person rule (iter 5). A capitalized
# token followed by a preference verb is usually a personal-preference memory
# ("Tom prefers the old layout") UNLESS the token is a known framework /
# language / tool / control-flow word. Keep this list conservative; missing
# entries cause false-positives on legitimate engineering memory.
$techProperNouns = @(
  'Always','Never','Prefer','Use','Check','Run','Set','Avoid','Verify','Ensure',
  'When','If','Before','After','For','In','On','A','An','The','This','These',
  'Avalonia','Salesforce','MuleSoft','DataWeave','Apex','PowerShell','Pwsh','Python',
  'MkDocs','GitHub','GitLab','Linux','Windows','MacOS','Docker','Kubernetes',
  'React','Vue','Angular','Node','TypeScript','JavaScript','Rust','Java','Kotlin',
  'Swift','Ruby','Bash','VS','Visual','Code','Studio','Microsoft','Google','Amazon',
  'AWS','Azure','OpenAI','Claude','Copilot','Cursor','Windsurf','Cline','Gearset',
  'Mocha','Jest','Pytest','Jupyter','Git','Mercurial','Jenkins','CircleCI'
)

function Score-Actionability([string]$t) {
  $score = 0.0
  $lc = $t.ToLowerInvariant()
  foreach ($v in $actionableVerbs)  { if ($lc -match "\b$v\b") { $score += 0.25 } }
  foreach ($f in $vagueFillers)     { if ($lc -match "\b$([regex]::Escape($f))\b") { $score -= 0.5 } }
  # Tautology shape: "if X then X" with same predicate echoed.
  if ($lc -match '\bif\s+.+\bthen\b.+\b(is|returns?)\b') { $score -= 1.0 }
  # Self-referential filler.
  if ($lc -match '\bagent\b.*\b(answered|responded|said)\b') { $score -= 0.75 }
  # World noise (weather / wifi / generic environment statements).
  if ($lc -match '\b(sunny|raining|wifi|weather)\b') { $score -= 1.0 }
  # Heartbeat / liveness noise: "still alive", "no new observations", "sync interval",
  # "keep-alive", "heartbeat". These are runtime telemetry, not memory.
  if ($lc -match '\b(heartbeat|still alive|no new observations?|sync interval|keep[- ]?alive)\b') { $score -= 1.5 }
  # Placeholder / WIP comments (iter 4, relaxed iter 6): TODO / TBD / FIXME / XXX / WIP
  # as a bare word. Iter 4 required a trailing : or - but that missed bullets
  # like "Required inputs: TBD. Mitigation: TODO." where the word ends with a
  # period. None of the legitimate keep examples use these words at all, so
  # the bare-word match is safe.
  if ($lc -match '\b(todo|tbd|fixme|wip|xxx)\b') { $score -= 1.5 }
  # Boot / liveness completion (iter 4): "loading complete", "system ready",
  # "ready for input", "all systems go", "startup complete". Distinct from the
  # heartbeat pattern in that these fire at a single moment.
  if ($lc -match '\b(loading complete|system ready|ready for input|all systems (go|ok)|startup complete|booted up)\b') { $score -= 1.5 }
  # UI event noise (iter 4): "User clicked / tapped / typed / scrolled / ..."
  # These are interaction logs, not engineering knowledge.
  if ($lc -match '\buser\s+(clicked|tapped|hovered|opened|closed|typed|scrolled|navigated|pressed|selected|dragged)\b') { $score -= 1.5 }
  # Non-content / hedge (iter 4): "it depends", "hard to say", "could be", "not sure".
  # A memory whose central claim is "it depends" carries no transferable rule.
  if ($lc -match '\b(it depends|hard to say|could be either|not sure|who knows)\b') { $score -= 1.0 }
  # Stale-status / rollout-in-progress (iter 4): "rolling out", "in progress",
  # "currently (running|deploying|processing|building)". Combined with a date
  # marker via the reusability rule, these classify as event-log noise.
  if ($lc -match '\b(rolling out|in progress|currently\s+(running|deploying|processing|building|loading))\b') { $score -= 0.5 }
  # Anecdotal singleton (iter 4): "worked when I", "broke when we", "happened
  # when I". A one-time anecdote is not a reusable lesson.
  if ($lc -match '\b(worked|broke|crashed|failed|happened)\s+when\s+(i|we)\b') { $score -= 1.5 }
  # Named-person preference (iter 5, Pattern A): "<Name> from <department>".
  # Tight pattern with low false-positive risk; catches the common
  # workplace-anecdote shape "Tom from accounting prefers ...". Uses -cmatch
  # (case-sensitive) because PowerShell's default -match is case-insensitive,
  # which would make [A-Z] match lowercase letters too.
  if ($t -cmatch '\b[A-Z][a-z]+\s+from\s+(accounting|marketing|sales|finance|hr|support|ops|engineering|product|legal|it|the\s+\w+\s+team)\b') { $score -= 1.5 }
  # Named-person preference (iter 5, Pattern B): capitalized token followed by
  # a personal-preference / opinion / hearsay verb. Excluded if the token is a
  # known framework / language / tool / control-flow word ($techProperNouns).
  # Catches "Sarah likes the dark theme", "John wants weekly emails", etc.
  # Uses -cmatch so [A-Z] really means uppercase (otherwise "you wants" matches).
  if ($t -cmatch '\b([A-Z][a-z]{1,15})\s+(prefers?|likes?|hates?|loves?|wants?|wishes|thinks|feels|believes|said|told|emailed|complained|asked\s+for)\b') {
    if ($techProperNouns -notcontains $Matches[1]) { $score -= 1.5 }
  }
  # Environmental sensory noise (iter 5): object word (coffee/tea/lunch/office/
  # room/weather/wifi/...) followed by "(was|is) <sensory adjective>". Catches
  # "Coffee was cold this morning and the office was loud" and generalizes the
  # narrower (sunny|raining|wifi|weather) wordlist above. Requires the object
  # anchor so legitimate engineering memory using "hot reload is unreliable"
  # or "quiet logging mode breaks CI" does not trip.
  if ($lc -match '\b(coffee|tea|lunch|breakfast|dinner|office|room|building|hallway|weather|wifi|internet|aircon|heater)\b.*\b(was|is)\s+(cold|hot|loud|quiet|warm|noisy|busy|calm|fast|slow|broken|down)\b') { $score -= 1.5 }
  # Heading-only extraction artifact (iter 6): a short bullet that ends in a
  # colon with no content after. Catches "How to confirm routing quality:"
  # which is a section header, not a memory. Length cap (80 chars) keeps the
  # rule from matching long sentences that happen to end with a colon.
  if ($t -match '^.{1,80}:\s*$') { $score -= 1.5 }
  # Aspirational vague (iter 6): "we should be better / able / careful / ..."
  # or "we should do / try / make / consider". States a wish without a rule.
  # Catches "We should be better at writing tests".
  if ($lc -match '\bwe should\s+(be\s+(better|able|good|careful|nicer|more|less)|do|try|make|consider)\b') { $score -= 1.5 }
  # Vague comparison (iter 6): "(generally|usually|mostly|often) (faster|
  # slower|better|...) than" -- combines two soft signals into one strong
  # reject signal without false-positiving on either alone. Catches
  # "X is generally faster than Y in most cases".
  if ($lc -match '\b(generally|usually|mostly|often)\s+(faster|slower|better|worse|easier|harder|simpler|cheaper|nicer)\s+than\b') { $score -= 1.5 }
  # Apology / meta-conversation (iter 6): "sorry, I missed your message" and
  # variants. These are chat-thread artifacts, not engineering memory.
  if ($lc -match "^sorry,?\s|\bi\s+(missed|forgot to see|didn'?t see)\s+your\b") { $score -= 1.5 }
  # Open-question shape (iter 6): "wondering whether|wondering if|not sure
  # whether|not sure if|should I|do we need|can we use". A memory that is
  # itself a question hasn't been resolved into a rule yet.
  if ($lc -match '^(wondering|not sure)\s+(whether|if)\b|\b(should i|do we need|can we use|what is the best way to)\b') { $score -= 1.5 }
  # Status-update ping (iter 7): "Status: OK", "nothing to report", "all
  # systems operational/nominal/green", "checked in", "everything is fine",
  # "just a (quick) update / check-in". Heartbeat-style chat noise without
  # a portable rule. Catches "Status: OK. Nothing to report." and
  # "GitHub status page shows all systems operational".
  if ($lc -match '^\s*(status|update)\s*[:\-]|\b(nothing to report|all systems (operational|nominal|green)|everything (is fine|looks good)|just a (quick )?(update|check[- ]?in))\b') { $score -= 1.5 }
  # Self-reminder shape (iter 7): "remember to <verb>". Personal note, not
  # a portable engineering rule. Catches "Remember to drink water during
  # long debugging sessions".
  if ($lc -match '\bremember to\b') { $score -= 1.5 }
  # Hedge stacking (iter 7): two or more soft hedges in the same bullet
  # ("might ... possibly", "may ... maybe", "could ... probably"). Single
  # hedges appear in legitimate engineering memory ("may not exist"); a
  # stack signals pure speculation. Requires one from each group.
  if (($lc -match '\b(might|may|could|perhaps)\b') -and ($lc -match '\b(possibly|maybe|probably|likely)\b')) { $score -= 1.5 }
  # Personal scheduling (iter 7): "I have/got a (meeting|standup|call|sync|
  # 1:1|appointment)". Calendar status, not memory.
  if ($lc -match '\bi\s+(have|got|''ve got)\s+(a\s+)?(meeting|standup|call|sync|1:1|appointment)\b') { $score -= 1.5 }
  # Greeting / sign-off (iter 7): "Hi team / hello all / hey everyone" or
  # "hope (everyone|you all) is doing well". Chat-thread artifacts.
  if ($lc -match '^(hi|hello|hey)\s+(team|all|everyone|folks)\b|\bhope (everyone|you all|y''all)\s+(is|are)\s+(doing\s+)?(well|great|good)\b') { $score -= 1.5 }
  # Side-note / off-topic (iter 7): "side note", "off topic", "btw", "by
  # the way", "fun fact". The bullet is explicitly tangential.
  if ($lc -match '\b(side note|off[- ]topic|btw|by the way|fun fact)\b') { $score -= 1.5 }
  # Pure user-speculation (iter 7): "the user (probably|likely|maybe|
  # presumably|might have) <verb>". Guessing about intent is not memory.
  if ($lc -match '\b(the\s+)?(user|customer|client)\s+(probably|likely|maybe|presumably|might have)\b') { $score -= 1.5 }
  # Restated documentation (iter 7): "according to the docs / documentation
  # / spec / manual / readme". Pointing at docs is not a memory; the rule
  # extracted from the docs would be. Allows an optional adjective between
  # "the/our" and the doc-type word ("according to the official docs").
  if ($lc -match '\baccording to (the |our )?(\w+\s+)?(docs|documentation|spec|specification|manual|readme)\b') { $score -= 1.5 }
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
  # Threshold is strictly > 0 (iter 4): items that score exactly 0 are
  # borderline noise (one weak negative signal balanced by the baseline
  # rewards) and should be rejected. No current keep item lands at 0;
  # lowest legitimate keep scores 0.85.
  $decision = if ($total -gt 0) { 'keep' } else { 'reject' }
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

if ($Unlabeled) {
  # Real-corpus mode: no ground truth, just report the distribution and
  # surface the lowest-scored items so a human can eyeball whether the
  # scorer would falsely reject real, useful memory.
  $scored = New-Object System.Collections.Generic.List[object]
  foreach ($line in $lines) {
    $rec = $null
    try { $rec = $line | ConvertFrom-Json } catch {
      [Console]::Error.WriteLine("Malformed JSONL line: $line")
      exit 2
    }
    $s = Score-Memory $rec.text
    $scored.Add([pscustomobject]@{
      id       = $rec.id
      source   = $rec.source
      decision = $s.decision
      total    = [math]::Round($s.total, 2)
      reason   = $s.reason
      text     = $rec.text
    })
  }

  $n      = $scored.Count
  $keep   = ($scored | Where-Object { $_.decision -eq 'keep' }).Count
  $reject = $n - $keep
  $totals = $scored | ForEach-Object { $_.total }
  $mean   = if ($n -gt 0) { [math]::Round(($totals | Measure-Object -Average).Average, 2) } else { 0 }
  $min    = if ($n -gt 0) { ($totals | Measure-Object -Minimum).Minimum } else { 0 }
  $max    = if ($n -gt 0) { ($totals | Measure-Object -Maximum).Maximum } else { 0 }
  $bins   = @{ 'lt -1' = 0; '-1..0' = 0; '0..1' = 0; '1..2' = 0; 'gt 2' = 0 }
  foreach ($t in $totals) {
    if     ($t -lt -1) { $bins['lt -1']++ }
    elseif ($t -lt  0) { $bins['-1..0']++ }
    elseif ($t -lt  1) { $bins['0..1']++  }
    elseif ($t -lt  2) { $bins['1..2']++  }
    else               { $bins['gt 2']++  }
  }

  Write-Host ""
  Write-Host "Admission-gate UNLABELED corpus run"
  Write-Host "  fixture     : $Fixture"
  Write-Host "  items       : $n"
  Write-Host "  predicted   : keep=$keep   reject=$reject   reject-rate=$([math]::Round(100.0 * $reject / [math]::Max(1,$n), 1))%"
  Write-Host "  total score : min=$min  mean=$mean  max=$max"
  Write-Host ("  distribution: lt -1={0}  -1..0={1}  0..1={2}  1..2={3}  gt 2={4}" -f $bins['lt -1'],$bins['-1..0'],$bins['0..1'],$bins['1..2'],$bins['gt 2'])
  Write-Host ""
  Write-Host "Lowest-scored $ShowWorst items (manual review -- would the gate be wrong?)"
  $scored | Sort-Object total | Select-Object -First $ShowWorst |
    ForEach-Object {
      $snippet = if ($_.text.Length -gt 110) { $_.text.Substring(0,107) + '...' } else { $_.text }
      Write-Host ("  [{0,5}] {1}  <- {2}" -f $_.total, $snippet, $_.source)
      if ($_.reason) { Write-Host ("          reason: {0}" -f $_.reason) }
    }
  Write-Host ""
  exit 0
}

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
