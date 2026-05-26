param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('decision','blocker','progress','dead-end','insight')]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    [string]$Note,

    [ValidateSet('General','Salesforce','MuleSoft')]
    [string]$Domain = 'General',

    [string[]]$Tags = @(),

    [string]$LogFile = 'observations.jsonl',

    [switch]$NoGate
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $repoRoot '_personal-root.ps1')
$personalRoot = Get-PersonalMemoryRoot $repoRoot
# If LogFile is absolute, honor it; else resolve under the personal data root.
if ([System.IO.Path]::IsPathRooted($LogFile)) {
    $logPath = $LogFile
} else {
    $logPath = Join-Path $personalRoot $LogFile
}

$entry = [ordered]@{
    timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
    type      = $Type
    domain    = $Domain
    tags      = $Tags
    note      = $Note
}

$json = ($entry | ConvertTo-Json -Compress -Depth 5)

# Iter 13: admission-gate write-path integration. Score the candidate before
# appending; rejected items are diverted to observations.rejected.jsonl so
# nothing is silently lost. Set MEMORY_GATE=off or pass -NoGate to bypass.
$gateOff = $NoGate -or ($env:MEMORY_GATE -eq 'off')
$scorer = Join-Path $repoRoot 'admission-gate\score_memory.py'
if (-not $gateOff -and (Test-Path $scorer)) {
    $pyCmd = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } elseif (Get-Command py -ErrorAction SilentlyContinue) { 'py' } else { $null }
    if ($pyCmd) {
        $candidate = (@{ text = $Note } | ConvertTo-Json -Compress)
        $decisionJson = $candidate | & $pyCmd $scorer --score-one 2>$null
        $gateExit = $LASTEXITCODE
        if ($gateExit -eq 3) {
            $reason = ''
            try { $reason = ($decisionJson | ConvertFrom-Json).reason } catch {}
            $rejectPath = Join-Path $personalRoot 'observations.rejected.jsonl'
            $rejected = [ordered]@{
                timestamp = $entry.timestamp
                type      = $Type
                domain    = $Domain
                tags      = $Tags
                note      = $Note
                reason    = $reason
            }
            Add-Content -Path $rejectPath -Value ($rejected | ConvertTo-Json -Compress -Depth 5) -Encoding UTF8
            Write-Host "[gate-reject] $Domain :: $Note" -ForegroundColor Yellow
            Write-Host "  reason: $reason  (logged to $rejectPath; rerun with -NoGate or MEMORY_GATE=off to bypass)" -ForegroundColor Yellow
            exit 3
        }
    }
}

Add-Content -Path $logPath -Value $json -Encoding UTF8

Write-Host "[$Type] $Domain :: $Note"
