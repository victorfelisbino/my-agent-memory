param(
    [string]$WorkspaceStorageRoot = "$env:APPDATA\Code\User\workspaceStorage",
    [string]$TranscriptDir = "",
    [string]$LogFile = 'observations.jsonl',
    [int]$SinceDays = 14,
    [int]$MaxPerRun = 50,
    [string[]]$ExtraTags = @(),
    [switch]$DryRun,
    [switch]$NoGate
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $repoRoot '_personal-root.ps1')
$personalRoot = Get-PersonalMemoryRoot $repoRoot
if ([System.IO.Path]::IsPathRooted($LogFile)) {
    $logPath = $LogFile
} else {
    $logPath = Join-Path $personalRoot $LogFile
}

if (-not (Test-Path $WorkspaceStorageRoot)) {
    Write-Error "Workspace storage root not found: $WorkspaceStorageRoot"
}

# Patterns: order matters. First match wins per message.
$patterns = @(
    [pscustomobject]@{ Type = 'blocker';  Regex = '(?i)\b(error|failed|cannot|won''t|stuck|broken|exception|traceback|undefined|null reference)\b'; Tag = 'auto-blocker' },
    [pscustomobject]@{ Type = 'dead-end'; Regex = '(?i)\b(reverted|rolled back|rollback|abandoned|gave up|backed out|didn''t work|did not work)\b'; Tag = 'auto-dead-end' },
    [pscustomobject]@{ Type = 'decision'; Regex = '(?i)\b(let''?s use|going with|chose|decided to|will use|switching to|adopt(ed|ing)?)\b'; Tag = 'auto-decision' },
    [pscustomobject]@{ Type = 'insight';  Regex = '(?i)\b(turns out|learned|realized|gotcha|surprise|aha|note that|key insight|root cause)\b'; Tag = 'auto-insight' },
    [pscustomobject]@{ Type = 'progress'; Regex = '(?i)\b(shipped|merged|landed|implemented|fixed the|resolved the)\b'; Tag = 'auto-progress' }
)

$domainKeywords = @(
    [pscustomobject]@{ Domain = 'Salesforce'; Keywords = @('salesforce','apex','soql','sobject','lwc','sf cli','sfdx','gearset','profile','permission set','flow') },
    [pscustomobject]@{ Domain = 'MuleSoft';   Keywords = @('mulesoft','mule ','anypoint','raml','cloudhub','dataweave') }
)

function Resolve-DomainFromText {
    param([string]$Text)
    $lower = $Text.ToLower()
    foreach ($rule in $domainKeywords) {
        foreach ($k in $rule.Keywords) {
            if ($lower -match [regex]::Escape($k)) { return $rule.Domain }
        }
    }
    return 'General'
}

# Secret patterns: applied to every captured note before write.
$secretPatterns = @(
    @{ Pattern = '(?i)bearer\s+[A-Za-z0-9._\-]{20,}'; Replacement = 'Bearer [REDACTED]' },
    @{ Pattern = 'eyJ[A-Za-z0-9._\-]{20,}'; Replacement = '[REDACTED_JWT]' },
    @{ Pattern = '00D[A-Za-z0-9]{12,18}![A-Za-z0-9._\-]+'; Replacement = '[REDACTED_SF_SESSION]' },
    @{ Pattern = '\b(sk|pk|rk)_(live|test)_[A-Za-z0-9]{16,}\b'; Replacement = '[REDACTED_STRIPE_KEY]' },
    @{ Pattern = '\bxox[bpasr]-[A-Za-z0-9-]{10,}\b'; Replacement = '[REDACTED_SLACK_TOKEN]' },
    @{ Pattern = '\bgh[pousr]_[A-Za-z0-9]{30,}\b'; Replacement = '[REDACTED_GITHUB_TOKEN]' },
    @{ Pattern = '\bAKIA[0-9A-Z]{16}\b'; Replacement = '[REDACTED_AWS_KEY]' },
    @{ Pattern = '(?i)(password|passwd|pwd|secret|api[_-]?key|token|auth[_-]?key)\s*[:=]\s*[''"]?[^\s''"]{6,}'; Replacement = '$1=[REDACTED]' },
    @{ Pattern = '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'; Replacement = '[REDACTED_EMAIL]' }
)

function Remove-Secrets {
    param([string]$Text)
    $clean = $Text
    foreach ($sp in $secretPatterns) {
        $clean = [regex]::Replace($clean, $sp.Pattern, $sp.Replacement)
    }
    return $clean
}

# Collect transcript directories
$transcriptDirs = @()
if ($TranscriptDir -and (Test-Path $TranscriptDir)) {
    $transcriptDirs += (Resolve-Path $TranscriptDir).Path
} else {
    foreach ($workspaceDir in Get-ChildItem $WorkspaceStorageRoot -Directory) {
        $candidate = Join-Path $workspaceDir.FullName 'GitHub.copilot-chat\transcripts'
        if (Test-Path $candidate) { $transcriptDirs += $candidate }
    }
}

if ($transcriptDirs.Count -eq 0) {
    Write-Host "No transcript directories found. Nothing to capture."
    return
}

# Load existing log and build dedupe set (hash of type + first 120 chars normalized)
function Get-Hash {
    param([string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA1]::Create()
    return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').Substring(0,16)
}

$existingHashes = New-Object 'System.Collections.Generic.HashSet[string]'
if (Test-Path $logPath) {
    foreach ($line in Get-Content $logPath -Encoding UTF8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $obj = $line | ConvertFrom-Json -ErrorAction Stop
            $key = "$($obj.type)|$(($obj.note | Out-String).Trim().ToLower().Substring(0, [Math]::Min(120, $obj.note.Length)))"
            [void]$existingHashes.Add((Get-Hash $key))
        } catch {}
    }
}

$cutoff = (Get-Date).AddDays(-$SinceDays)
$candidates = @()

foreach ($dir in $transcriptDirs | Select-Object -Unique) {
    foreach ($file in Get-ChildItem $dir -Filter *.jsonl -File) {
        if ($file.LastWriteTime -lt $cutoff) { continue }
        foreach ($line in Get-Content $file.FullName -Encoding UTF8) {
            try {
                $obj = $line | ConvertFrom-Json -ErrorAction Stop
            } catch { continue }

            $content = $null
            $role = $null
            if ($obj.type -eq 'user.message' -and $obj.data.content) {
                $content = [string]$obj.data.content
                $role = 'user'
            } elseif ($obj.type -eq 'assistant.message' -and $obj.data.content) {
                $content = [string]$obj.data.content
                $role = 'assistant'
            }
            if (-not $content) { continue }
            if ($content.Length -lt 20 -or $content.Length -gt 1000) { continue }

            # Noise filters: skip code-heavy messages
            $backtickCount = ([regex]::Matches($content, '`')).Count
            if ($backtickCount -gt 6) { continue }
            if ($content -match '^\s*```') { continue }
            $pipeCount = ([regex]::Matches($content, '\|')).Count
            if ($pipeCount -gt 4) { continue }

            $ts = [datetime]::MinValue
            if ($obj.timestamp) {
                [void][datetime]::TryParse([string]$obj.timestamp, [ref]$ts)
            }
            if ($ts -eq [datetime]::MinValue) { $ts = $file.LastWriteTime }
            if ($ts -lt $cutoff) { continue }

            foreach ($p in $patterns) {
                if ($content -match $p.Regex) {
                    # Take the matching sentence (best-effort)
                    $sentence = $content
                    $sentences = [regex]::Split($content, '(?<=[.!?])\s+')
                    foreach ($s in $sentences) {
                        if ($s -match $p.Regex) { $sentence = $s; break }
                    }
                    $sentence = ($sentence -replace '\s+', ' ').Trim()
                    if ($sentence.Length -gt 240) {
                        $sentence = $sentence.Substring(0, 237) + '...'
                    }
                    $sentence = Remove-Secrets -Text $sentence

                    $domain = Resolve-DomainFromText -Text $content
                    $key = "$($p.Type)|$($sentence.ToLower().Substring(0, [Math]::Min(120, $sentence.Length)))"
                    $hash = Get-Hash $key
                    if ($existingHashes.Contains($hash)) { break }
                    [void]$existingHashes.Add($hash)

                    $tagList = @($p.Tag, "source:$role")
                    if ($ExtraTags -and $ExtraTags.Count -gt 0) { $tagList += $ExtraTags }
                    $candidates += [pscustomobject]@{
                        Timestamp = $ts
                        Type      = $p.Type
                        Domain    = $domain
                        Tags      = $tagList
                        Note      = $sentence
                    }
                    break
                }
            }
        }
    }
}

$candidates = @($candidates | Sort-Object Timestamp -Descending | Select-Object -First $MaxPerRun)

if ($candidates.Count -eq 0) {
    Write-Host "No new observations to capture."
    return
}

if ($DryRun) {
    Write-Host "DRY RUN: would append $($candidates.Count) observation(s)."
    foreach ($c in $candidates) {
        Write-Host ("  [{0}] {1} | {2} - {3}" -f $c.Type, $c.Timestamp.ToString('yyyy-MM-dd'), $c.Domain, $c.Note)
    }
    return
}
# Iter 14: admission-gate write-path integration for the automated capture path.
# Same contract as capture-observation.ps1: per-item score via score_memory.py
# --score-one; rejects diverted to observations.rejected.jsonl with reason; set
# MEMORY_GATE=off or pass -NoGate to bypass (e.g. for backfills).
$gateOff = $NoGate -or ($env:MEMORY_GATE -eq 'off')
$scorer = Join-Path $repoRoot 'admission-gate\score_memory.py'
$pyCmd = $null
if (-not $gateOff -and (Test-Path $scorer)) {
    $pyCmd = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } elseif (Get-Command py -ErrorAction SilentlyContinue) { 'py' } else { $null }
}
$rejectPath = Join-Path $personalRoot 'observations.rejected.jsonl'
$keptCount = 0
$rejectedCount = 0

foreach ($c in $candidates) {
    $entry = [ordered]@{
        timestamp = $c.Timestamp.ToString('yyyy-MM-ddTHH:mm:ssK')
        type      = $c.Type
        domain    = $c.Domain
        tags      = $c.Tags
        note      = $c.Note
    }
    $json = ($entry | ConvertTo-Json -Compress -Depth 5)

    if ($pyCmd) {
        $candidate = (@{ text = $c.Note } | ConvertTo-Json -Compress)
        $decisionJson = $candidate | & $pyCmd $scorer --score-one 2>$null
        if ($LASTEXITCODE -eq 3) {
            $reason = ''
            try { $reason = ($decisionJson | ConvertFrom-Json).reason } catch {}
            $rejected = [ordered]@{
                timestamp = $entry.timestamp
                type      = $c.Type
                domain    = $c.Domain
                tags      = $c.Tags
                note      = $c.Note
                reason    = $reason
                source    = 'auto-capture'
            }
            Add-Content -Path $rejectPath -Value ($rejected | ConvertTo-Json -Compress -Depth 5) -Encoding UTF8
            $rejectedCount++
            continue
        }
    }

    Add-Content -Path $logPath -Value $json -Encoding UTF8
    $keptCount++
}

if ($rejectedCount -gt 0) {
    Write-Host "Appended $keptCount auto-captured observation(s) to $logPath; gate rejected $rejectedCount (see $rejectPath)"
} else {
    Write-Host "Appended $keptCount auto-captured observation(s) to $logPath"
}
