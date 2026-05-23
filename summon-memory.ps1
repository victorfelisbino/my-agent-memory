param(
    [ValidateSet('Auto','General','Salesforce','MuleSoft')]
    [string]$Domain = 'Auto',
    [Parameter(Mandatory=$true)]
    [string]$Task,
    [int]$Top = 10,
    [int]$TopObservations = 5,
    [int]$ObservationDays = 30,
    [string]$ObservationsFile = 'observations.jsonl',
    [string]$OutputFile = 'active-memory-brief.md',
    [switch]$Preflight,
    [switch]$Compact
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $repoRoot '_personal-root.ps1')
$personalRoot = Get-PersonalMemoryRoot $repoRoot
$outputPath = Join-Path $personalRoot $OutputFile

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $base = (Resolve-Path $BasePath).Path
    $target = (Resolve-Path $TargetPath).Path

    if (-not $base.EndsWith('\')) {
        $base += '\'
    }

    $baseUri = New-Object System.Uri($base)
    $targetUri = New-Object System.Uri($target)
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function Get-NormalizedWords {
    param([string]$Text)

    $clean = ($Text.ToLower() -replace '[^a-z0-9\s-]', ' ')
    $parts = $clean -split '\s+'

    $stop = @(
        'the','and','for','with','from','that','this','your','about','into','will',
        'have','need','using','when','what','where','how','why','can','could','should',
        'would','make','more','less','then','than','also','just','task','work','project',
        'create','build','setup','set','get','use','api','app','access','domain'
    )

    $words = @()
    foreach ($p in $parts) {
        if ($p.Length -lt 4) { continue }
        if ($stop -contains $p) { continue }
        $words += $p
    }

    return $words | Select-Object -Unique
}

function Resolve-DomainFromTask {
    param([string]$TaskText)

    $lower = $TaskText.ToLower()
    $domainRules = @(
        [pscustomobject]@{
            Domain = 'Salesforce'
            Keywords = @('salesforce','apex','soql','sobject','lwc','connected app','sfdc','sf cli','sf org')
        },
        [pscustomobject]@{
            Domain = 'MuleSoft'
            Keywords = @('mulesoft','mule','anypoint','raml','mule app','mule flow','exchange','cloudhub')
        }
    )

    $bestDomain = 'General'
    $bestScore = 0

    foreach ($rule in $domainRules) {
        $score = 0
        foreach ($k in $rule.Keywords) {
            if ($lower -match [regex]::Escape($k)) {
                $score++
            }
        }

        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestDomain = $rule.Domain
        }
    }

    return $bestDomain
}

# Classify task into a coarse type. Used as a router hint for Copilot auto-mode
# so the cheaper-but-correct model is picked instead of the heaviest one by default.
function Resolve-TaskType {
    param([string]$TaskText)
    $t = $TaskText.ToLower()
    $rules = @(
        @{ Type = 'debug';    Pattern = '\b(debug|fix|error|broken|fails|failing|stack ?trace|exception|why (does|is)|null|undefined|crash)\b' },
        @{ Type = 'refactor'; Pattern = '\b(refactor|rename|extract|simplify|cleanup|reorganize|move|split|consolidate)\b' },
        @{ Type = 'review';   Pattern = '\b(review|audit|check|analyze|assess|evaluate|critique)\b' },
        @{ Type = 'design';   Pattern = '\b(design|architect|approach|propose|plan|spec|how should|trade.?off|decide)\b' },
        @{ Type = 'test';     Pattern = '\b(test|spec|coverage|unit|integration test|e2e|mock)\b' },
        @{ Type = 'explain';  Pattern = '\b(explain|what is|how does|why does|describe|walk me through|summarize)\b' },
        @{ Type = 'generate'; Pattern = '\b(implement|build|create|add|write|generate|scaffold|new)\b' }
    )
    foreach ($r in $rules) {
        if ($t -match $r.Pattern) { return $r.Type }
    }
    return 'generate'
}

# Coarse complexity estimate. Used as a router hint.
function Resolve-Complexity {
    param([string]$TaskText)
    $t = $TaskText.ToLower()
    $heavySignals = @('migration','migrate','schema','integration','architecture','redesign','refactor.*module','deploy.*pipeline','multi.?step','end.?to.?end','cross.?system')
    foreach ($s in $heavySignals) { if ($t -match $s) { return 'complex' } }
    $andCount = ([regex]::Matches($t, '\band\b')).Count
    if ($TaskText.Length -lt 60 -and $andCount -le 1) { return 'trivial' }
    if ($TaskText.Length -gt 220 -or $andCount -ge 3) { return 'complex' }
    return 'standard'
}

# Map (task type x complexity) to an auto-router hint string. Advisory only.
# Goal: cheapest model that won't waste turns on the task. Auto-mode in Copilot
# applies a ~10% discount when you let it pick; making the pick easy = real savings.
function Resolve-ModelHint {
    param([string]$TaskType, [string]$Complexity)
    if ($Complexity -eq 'trivial')                              { return 'fast (auto should pick a small/cheap model)' }
    if ($TaskType -in @('explain','review','design'))           { return 'reasoning (auto should pick a strong reasoning model)' }
    if ($Complexity -eq 'complex')                              { return 'deep (auto should pick the top-tier model)' }
    return 'balanced (auto default is fine)'
}

function Get-FreshnessScore {
    param([datetime]$LastWrite)

    $days = (New-TimeSpan -Start $LastWrite -End (Get-Date)).TotalDays
    if ($days -le 7) { return 3 }
    if ($days -le 30) { return 2 }
    if ($days -le 90) { return 1 }
    return 0
}

function Get-ConfidenceScoreFromText {
    param([string]$Text)

    $match = [regex]::Match($Text, '(?im)^\s*[-*]?\s*confidence:\s*(low|medium|high)\b')
    if (-not $match.Success) { return 0 }

    switch ($match.Groups[1].Value.ToLower()) {
        'high' { return 2 }
        'medium' { return 1 }
        'low' { return -1 }
        default { return 0 }
    }
}

function Get-VerificationScoreFromText {
    param([string]$Text)

    $match = [regex]::Match($Text, '(?im)^\s*[-*]?\s*last\s*verified(?:\s*date)?\s*:\s*(\d{4}-\d{2}-\d{2})\b')
    if (-not $match.Success) { return -1 }

    $verifiedDate = $null
    if (-not [datetime]::TryParse($match.Groups[1].Value, [ref]$verifiedDate)) {
        return -1
    }

    $days = (New-TimeSpan -Start $verifiedDate -End (Get-Date)).TotalDays
    if ($days -le 30) { return 2 }
    if ($days -le 90) { return 1 }
    if ($days -le 180) { return 0 }
    return -1
}

function Get-CandidateFiles {
    param([string]$Root, [string]$SelectedDomain, [string]$GeneratedFile)

    $files = @()

    $rootFiles = Get-ChildItem -Path $Root -Filter *.md -File | Where-Object {
        $_.Name -notin @('memory-scoreboard.md','memory-top-patterns.md', $GeneratedFile)
    }
    $files += $rootFiles

    $generalDir = Join-Path $Root 'domains\general'
    if (Test-Path $generalDir) {
        $files += Get-ChildItem -Path $generalDir -Filter *.md -File
    }

    $domainDir = Join-Path $Root ("domains\" + $SelectedDomain.ToLower())
    if (Test-Path $domainDir) {
        $files += Get-ChildItem -Path $domainDir -Filter *.md -File
    }

    return $files | Select-Object -Unique
}

function Score-Line {
    param(
        [string]$Line,
        [string[]]$Keywords,
        [string]$TaskText,
        [string]$ActiveDomain
    )

    $score = 0
    $lower = $Line.ToLower()

    foreach ($k in $Keywords) {
        if ($lower -match [regex]::Escape($k)) {
            $score += 2
        }
    }

    if ($lower -match '^#{1,3}\s') { $score += 1 }
    if ($lower -match 'guardrail|risk|evidence|checklist|verify|oauth|token|auth|deploy|permission') {
        $score += 1
    }

    if ($TaskText.ToLower() -match 'salesforce' -and $lower -match 'salesforce|sf ') {
        $score += 2
    }

    if ($ActiveDomain -eq 'Salesforce' -and $lower -match 'salesforce|sf |oauth|token|connected app|permission set') {
        $score += 1
    }

    if ($ActiveDomain -eq 'MuleSoft' -and $lower -match 'mulesoft|anypoint|raml|cloudhub|exchange') {
        $score += 1
    }

    return $score
}

$resolvedDomain = if ($Domain -eq 'Auto') { Resolve-DomainFromTask -TaskText $Task } else { $Domain }
$taskType   = Resolve-TaskType  -TaskText $Task
$complexity = Resolve-Complexity -TaskText $Task
$modelHint  = Resolve-ModelHint  -TaskType $taskType -Complexity $complexity
$keywords = Get-NormalizedWords -Text $Task
$candidateFiles = Get-CandidateFiles -Root $repoRoot -SelectedDomain $resolvedDomain -GeneratedFile $OutputFile

function Get-RelevantObservations {
    param(
        [string]$Path,
        [string[]]$Keywords,
        [string]$ActiveDomain,
        [int]$Days,
        [int]$Limit
    )

    if (-not (Test-Path $Path)) { return @() }

    $cutoff = (Get-Date).AddDays(-$Days)
    $results = @()

    foreach ($line in Get-Content $Path -Encoding UTF8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $obj = $line | ConvertFrom-Json -ErrorAction Stop
        } catch { continue }

        $ts = [datetime]::MinValue
        if (-not [datetime]::TryParse([string]$obj.timestamp, [ref]$ts)) { continue }
        if ($ts -lt $cutoff) { continue }

        $hay = ("$($obj.note) $($obj.tags -join ' ')").ToLower()
        $score = 0
        foreach ($k in $Keywords) {
            if ($hay -match [regex]::Escape($k)) { $score += 2 }
        }

        if ($obj.domain -eq $ActiveDomain) { $score += 2 }
        elseif ($obj.domain -eq 'General') { $score += 1 }

        switch ($obj.type) {
            'decision' { $score += 2 }
            'blocker'  { $score += 2 }
            'dead-end' { $score += 1 }
            'insight'  { $score += 1 }
        }

        $ageDays = (New-TimeSpan -Start $ts -End (Get-Date)).TotalDays
        if ($ageDays -le 3)  { $score += 2 }
        elseif ($ageDays -le 7)  { $score += 1 }

        if ($score -le 0) { continue }

        $results += [pscustomobject]@{
            Score     = $score
            Timestamp = $ts
            Type      = $obj.type
            Domain    = $obj.domain
            Tags      = $obj.tags
            Note      = $obj.note
        }
    }

    return @($results | Sort-Object @{ Expression = { $_.Score }; Descending = $true }, @{ Expression = { $_.Timestamp }; Descending = $true } | Select-Object -First $Limit)
}

$observationsPath = Join-Path $personalRoot $ObservationsFile
$rankedObservations = Get-RelevantObservations -Path $observationsPath -Keywords $keywords -ActiveDomain $resolvedDomain -Days $ObservationDays -Limit $TopObservations

if ($candidateFiles.Count -eq 0) {
    throw "No markdown files found to search."
}

$snippets = @()

foreach ($file in $candidateFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8
    $fileText = $lines -join "`n"
    $confidenceScore = Get-ConfidenceScoreFromText -Text $fileText
    $verificationScore = Get-VerificationScoreFromText -Text $fileText
    $freshnessScore = Get-FreshnessScore -LastWrite $file.LastWriteTime

    $i = 0
    foreach ($line in $lines) {
        $i++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        $baseScore = Score-Line -Line $line -Keywords $keywords -TaskText $Task -ActiveDomain $resolvedDomain
        $score = $baseScore + $freshnessScore + $confidenceScore + $verificationScore
        if ($score -le 0) { continue }

        $snippets += [pscustomobject]@{
            Score = $score
            BaseScore = $baseScore
            FreshnessScore = $freshnessScore
            ConfidenceScore = $confidenceScore
            VerificationScore = $verificationScore
            File = $file.Name
            RelPath = Get-RelativePath -BasePath $repoRoot -TargetPath $file.FullName
            Line = $i
            Text = $line.Trim()
        }
    }
}

# When compact, keep only the strongest snippets (saves tokens for auto-router).
if ($Compact) {
    $rankedAll = $snippets |
        Where-Object { $_.Text -notmatch 'summon-memory\.(ps1|sh)' } |
        Sort-Object @{ Expression = { $_.Score }; Descending = $true }, @{ Expression = { $_.VerificationScore }; Descending = $true }, @{ Expression = { $_.FreshnessScore }; Descending = $true }, @{ Expression = { $_.File }; Ascending = $true }
    $ranked = $rankedAll | Select-Object -First ([Math]::Min(5, $Top))
} else {
    $ranked = $snippets |
        Where-Object { $_.Text -notmatch 'summon-memory\.(ps1|sh)' } |
        Sort-Object @{ Expression = { $_.Score }; Descending = $true }, @{ Expression = { $_.VerificationScore }; Descending = $true }, @{ Expression = { $_.FreshnessScore }; Descending = $true }, @{ Expression = { $_.File }; Ascending = $true } |
        Select-Object -First $Top
}

$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$out = @()
# --- Router hints (always first; lets Copilot auto-mode classify and pick the cheapest correct model) ---
$out += '# Active Memory Brief'
$out += ''
$out += '## Router hints (for Copilot auto-mode)'
$out += "- Task type : $taskType"
$out += "- Complexity: $complexity"
$out += "- Domain    : $resolvedDomain"
$out += "- Suggested : $modelHint"
$out += "- Task      : $Task"
$out += ''

if (-not $Compact) {
    $out += "Updated: $now"
    $out += "Domain selection: $Domain"
    $out += 'Scoring: total = relevance + freshness + confidence + verification-freshness'
    $out += 'Confidence score: high=+2, medium=+1, low=-1, missing=0'
    $out += 'Verification score: <=30d=+2, <=90d=+1, <=180d=0, stale/missing=-1'
    $out += ''
}

$out += '## Suggested snippets'
$out += ''

if ($ranked.Count -eq 0) {
    $out += '- No strong matches found. Add a new note for this scenario and rerun.'
} else {
    foreach ($r in $ranked) {
        if ($Compact) {
            $out += "- $($r.RelPath):$($r.Line) - $($r.Text)"
        } else {
            $out += "- [$($r.Score) = $($r.BaseScore) relevance + $($r.FreshnessScore) freshness + $($r.ConfidenceScore) confidence + $($r.VerificationScore) verification] $($r.RelPath):$($r.Line) - $($r.Text)"
        }
    }
}

$out += ''
$out += "## Recent observations (last $ObservationDays days)"
$out += ''
$obsLimit = if ($Compact) { 3 } else { $rankedObservations.Count }
if ($rankedObservations.Count -eq 0) {
    $out += '- No relevant recent observations. Capture decisions/blockers with capture-observation to build this stream.'
} else {
    foreach ($o in ($rankedObservations | Select-Object -First $obsLimit)) {
        $date = $o.Timestamp.ToString('yyyy-MM-dd')
        $tagStr = if ($o.Tags -and $o.Tags.Count -gt 0) { " [$(($o.Tags) -join ', ')]" } else { '' }
        if ($Compact) {
            $out += "- $date $($o.Type) - $($o.Note)"
        } else {
            $out += "- [$($o.Score)] $date | $($o.Type) | $($o.Domain)$tagStr - $($o.Note)"
        }
    }
}

# Active threads summary (cross-machine, generated by sync-memory.ps1).
# Tells future Copilot which projects are live on which machines.
# Skipped in compact mode to save tokens.
$threadsPath = Join-Path $personalRoot 'active-threads.md'
if ((-not $Compact) -and (Test-Path $threadsPath)) {
    $threadLines = Get-Content $threadsPath -Encoding UTF8
    $headerLines = @()
    $machinesLine = ''
    $groups = @()
    $currentGroup = $null
    foreach ($line in $threadLines) {
        if ($line -match '^Machines seen:') { $machinesLine = $line; continue }
        if ($line -match '^##\s+(.+)$') {
            if ($currentGroup) { $groups += $currentGroup }
            $currentGroup = [pscustomobject]@{ Name = $Matches[1]; Meta = @() }
            continue
        }
        if ($currentGroup -and $line -match '^- Last activity:') {
            $currentGroup.Meta += $line
        }
    }
    if ($currentGroup) { $groups += $currentGroup }

    if ($groups.Count -gt 0) {
        $out += ''
        $out += '## Active threads (cross-machine, last 14 days)'
        $out += ''
        if ($machinesLine) { $out += "- $machinesLine" }
        foreach ($g in ($groups | Select-Object -First 5)) {
            $meta = if ($g.Meta.Count -gt 0) { $g.Meta[0].TrimStart('- ') } else { '' }
            $out += "- **$($g.Name)** -- $meta"
        }
    }
}

$out += ''
if (-not $Compact) {
    $out += '## Usage'
    $out += ''
    $out += 'Copy this brief into your next Copilot prompt to force high-signal context.'
}

Set-Content -Path $outputPath -Value ($out -join "`n") -Encoding UTF8

# Rough token estimate: chars/4 (good enough to spot when a brief is bloated).
$briefBytes = (Get-Content -Path $outputPath -Raw -Encoding UTF8).Length
$estTokens = [int]($briefBytes / 4)

Write-Host "Updated: $outputPath"
Write-Host "Mode: $(if ($Compact) { 'compact' } else { 'full' })  |  Files scanned: $($candidateFiles.Count)  |  Snippets: $($ranked.Count)  |  Observations: $(if ($Compact) { [Math]::Min(3, $rankedObservations.Count) } else { $rankedObservations.Count })"
Write-Host "Router hints -> type=$taskType complexity=$complexity domain=$resolvedDomain suggested=$modelHint"
Write-Host "Brief size  -> $briefBytes chars (~$estTokens tokens)"

if ($Preflight) {
    $briefContent = Get-Content -Path $outputPath -Raw -Encoding UTF8
    $prompt = @()
    $prompt += '----- COPILOT PREFLIGHT PROMPT -----'
    $prompt += "Router hints (let auto-mode use these to pick the cheapest correct model):"
    $prompt += "  task=$taskType  complexity=$complexity  domain=$resolvedDomain  suggested=$modelHint"
    $prompt += "Task: $Task"
    $prompt += ''
    $prompt += 'Use this memory brief as highest-priority context:'
    $prompt += ''
    $prompt += $briefContent.Trim()
    $prompt += ''
    $prompt += 'Instructions:'
    $prompt += '- Stay scoped to the task above. Do not expand scope without asking.'
    $prompt += '- Prefer commands and guardrails from the brief when they fit.'
    $prompt += '- If required values are org/project-specific, ask for them explicitly (one batched question, not many).'
    $prompt += '- If memory conflicts with current codebase reality, trust current evidence and state the mismatch.'
    $prompt += '- Skip restating context back to me. Go straight to the answer or the next action.'
    $prompt += '----- END PREFLIGHT PROMPT -----'

    Write-Host ''
    Write-Host ($prompt -join "`n")
}