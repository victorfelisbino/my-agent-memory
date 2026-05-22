param(
    [string]$WorkspaceStorageRoot = "$env:APPDATA\Code\User\workspaceStorage",
    [string]$TranscriptDir = "",
    [string]$OutputDir = "$env:APPDATA\Code\User\memories"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $WorkspaceStorageRoot)) {
    Write-Error "Workspace storage root not found: $WorkspaceStorageRoot"
}

$patterns = @(
    [pscustomobject]@{ Trigger = 'did it deploy'; Label = 'False deploy confidence'; Severity = 'P0'; Domain = 'General'; Guardrail = 'Require branch, PR diff, and org deploy report before closure.' },
    [pscustomobject]@{ Trigger = 'deploy'; Label = 'Deploy churn'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Use pre-close verification bundle every time.' },
    [pscustomobject]@{ Trigger = 'qa'; Label = 'QA promotion risk'; Severity = 'P1'; Domain = 'Salesforce'; Guardrail = 'Confirm branch diff against qa before PR.' },
    [pscustomobject]@{ Trigger = 'pr'; Label = 'PR workflow confusion'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Check PR delta exists before opening/reviewing.' },
    [pscustomobject]@{ Trigger = 'branch'; Label = 'Branch drift'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Track base and head branch parity before promotion.' },
    [pscustomobject]@{ Trigger = 'gearset'; Label = 'Gearset propagation misses'; Severity = 'P1'; Domain = 'Salesforce'; Guardrail = 'Back-propagate bot/suggestion commits to base branch.' },
    [pscustomobject]@{ Trigger = 'main_-_stg'; Label = 'Staging branch validation failures'; Severity = 'P1'; Domain = 'Salesforce'; Guardrail = 'Audit first failing component before retrigger.' },
    [pscustomobject]@{ Trigger = 'validation'; Label = 'Validation loop repeats'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Capture root cause before rerun.' },
    [pscustomobject]@{ Trigger = 'failed'; Label = 'Failure without diagnosis'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Log first failing metadata component and owner.' },
    [pscustomobject]@{ Trigger = 'profile'; Label = 'Profile metadata cross-reference errors'; Severity = 'P1'; Domain = 'Salesforce'; Guardrail = 'Audit profileActionOverrides/profile refs pre-deploy.' },
    [pscustomobject]@{ Trigger = 'permission'; Label = 'Permission visibility mismatch'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Validate FLS + perm assignment + layout/page activation.' },
    [pscustomobject]@{ Trigger = 'layout'; Label = 'Layout-only fixes miss access path'; Severity = 'P1'; Domain = 'General'; Guardrail = 'Test as target persona, not admin only.' },
    [pscustomobject]@{ Trigger = 'try again'; Label = 'Retry without learning'; Severity = 'P2'; Domain = 'General'; Guardrail = 'Require one-line root cause hypothesis before retry.' }
)

$transcriptDirs = @()
if ($TranscriptDir -and (Test-Path $TranscriptDir)) {
    $transcriptDirs += (Resolve-Path $TranscriptDir).Path
} else {
    foreach ($workspaceDir in Get-ChildItem $WorkspaceStorageRoot -Directory) {
        $candidate = Join-Path $workspaceDir.FullName 'GitHub.copilot-chat\transcripts'
        if (Test-Path $candidate) {
            $transcriptDirs += $candidate
        }
    }
}

if ($transcriptDirs.Count -eq 0) {
    Write-Error "No transcript directories found."
}

$messages = @()
$workspaceCount = 0
foreach ($dir in $transcriptDirs | Select-Object -Unique) {
    $workspaceCount++
    foreach ($file in Get-ChildItem $dir -Filter *.jsonl -File) {
        foreach ($line in Get-Content $file.FullName -Encoding UTF8) {
            try {
                $obj = $line | ConvertFrom-Json -ErrorAction Stop
                if ($obj.type -eq 'user.message' -and $obj.data.content) {
                    $messages += [pscustomobject]@{
                        File = $file.Name
                        Text = $obj.data.content.ToLower()
                        Timestamp = $obj.timestamp
                        TranscriptDir = $dir
                    }
                }
            } catch {
            }
        }
    }
}

if ($messages.Count -eq 0) {
    Write-Error "No user messages found in transcript files."
}

$scoreRows = foreach ($p in $patterns) {
    $escaped = [regex]::Escape($p.Trigger)
    $count = ($messages | Where-Object { $_.Text -match $escaped } | Measure-Object).Count
    [pscustomobject]@{
        Severity = $p.Severity
        Domain = $p.Domain
        Pattern = $p.Label
        Trigger = $p.Trigger
        Count = $count
        Guardrail = $p.Guardrail
    }
}

$severityWeight = @{ P0 = 3; P1 = 2; P2 = 1 }
$ranked = $scoreRows | Sort-Object @{ Expression = { $_.Count * $severityWeight[$_.Severity] }; Descending = $true }, @{ Expression = { $_.Count }; Descending = $true }
$top20 = $ranked | Select-Object -First 20

$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$scoreboardPath = Join-Path $OutputDir 'memory-scoreboard.md'
$topPatternsPath = Join-Path $OutputDir 'memory-top-patterns.md'

$scoreboard = @()
$scoreboard += '# Memory Scoreboard'
$scoreboard += ''
$scoreboard += "Updated: $now"
$scoreboard += ''
$scoreboard += '| Priority | Severity | Domain | Pattern | Trigger | Count | Guardrail |'
$scoreboard += '|---|---|---|---|---|---:|---|'

$idx = 1
foreach ($row in $top20) {
    $scoreboard += "| $idx | $($row.Severity) | $($row.Domain) | $($row.Pattern) | $($row.Trigger) | $($row.Count) | $($row.Guardrail) |"
    $idx++
}

Set-Content -Path $scoreboardPath -Value ($scoreboard -join "`n") -Encoding UTF8

$top = @()
$top += '# Top Failure Patterns'
$top += ''
$top += "Updated: $now"
$top += ''

foreach ($row in $top20) {
    if ($row.Count -le 0) { continue }
    $top += "## [$($row.Severity)] $($row.Pattern)"
    $top += "- Domain: $($row.Domain)"
    $top += "- Trigger: $($row.Trigger)"
    $top += "- Frequency: $($row.Count)"
    $top += "- Guardrail: $($row.Guardrail)"
    $top += "- Action: Add or enforce this in gotchas.md and project-commands.md if missing."
    $top += ''
}

Set-Content -Path $topPatternsPath -Value ($top -join "`n") -Encoding UTF8

Write-Host "Updated: $scoreboardPath"
Write-Host "Updated: $topPatternsPath"
Write-Host "Messages processed: $($messages.Count)"
Write-Host "Transcript directories scanned: $workspaceCount"
