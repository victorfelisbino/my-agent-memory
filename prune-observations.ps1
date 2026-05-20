param(
    [int]$Days = 90,
    [string]$LogFile = 'observations.jsonl',
    [string]$ArchiveDir = 'observations-archive',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $repoRoot $LogFile
$archivePath = Join-Path $repoRoot $ArchiveDir

if (-not (Test-Path $logPath)) {
    Write-Host "No observations log at $logPath. Nothing to prune."
    return
}

$cutoff = (Get-Date).AddDays(-$Days)
$keep = @()
$archive = @{}

foreach ($line in Get-Content $logPath) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
    } catch { $keep += $line; continue }

    $ts = [datetime]::MinValue
    if (-not [datetime]::TryParse([string]$obj.timestamp, [ref]$ts)) {
        $keep += $line
        continue
    }

    if ($ts -ge $cutoff) {
        $keep += $line
    } else {
        $bucket = $ts.ToString('yyyy-MM')
        if (-not $archive.ContainsKey($bucket)) { $archive[$bucket] = @() }
        $archive[$bucket] += $line
    }
}

$movedTotal = ($archive.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
if (-not $movedTotal) { $movedTotal = 0 }

if ($movedTotal -eq 0) {
    Write-Host "No observations older than $Days days. Active log: $($keep.Count) entries."
    return
}

if ($DryRun) {
    Write-Host "DRY RUN: would archive $movedTotal observation(s), keep $($keep.Count) active."
    foreach ($bucket in $archive.Keys | Sort-Object) {
        Write-Host "  -> $bucket.jsonl : $($archive[$bucket].Count) entries"
    }
    return
}

if (-not (Test-Path $archivePath)) {
    New-Item -ItemType Directory -Path $archivePath | Out-Null
}

foreach ($bucket in $archive.Keys | Sort-Object) {
    $bucketPath = Join-Path $archivePath "$bucket.jsonl"
    Add-Content -Path $bucketPath -Value ($archive[$bucket] -join "`n") -Encoding UTF8
    Write-Host "Archived $($archive[$bucket].Count) -> $bucketPath"
}

Set-Content -Path $logPath -Value ($keep -join "`n") -Encoding UTF8
Write-Host "Active log now: $($keep.Count) entries. Archived: $movedTotal."
