param(
    [int]$Days = 7,
    [string]$LogFile = 'observations.jsonl',
    [string]$OutputFile = 'status-update.md'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $repoRoot $LogFile
$outputPath = Join-Path $repoRoot $OutputFile

if (-not (Test-Path $logPath)) {
    Write-Host "No observations log found at $logPath. Nothing to synthesize."
    return
}

$cutoff = (Get-Date).AddDays(-$Days)
$entries = @()

foreach ($line in Get-Content $logPath -Encoding UTF8) {
    if (-not $line.Trim()) { continue }
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
        $ts = [datetime]::Parse($obj.timestamp)
        if ($ts -ge $cutoff) {
            $entries += [pscustomobject]@{
                Timestamp = $ts
                Type      = $obj.type
                Domain    = $obj.domain
                Tags      = $obj.tags
                Note      = $obj.note
            }
        }
    } catch {
        Write-Warning "Skipping malformed line: $line"
    }
}

$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$total = $entries.Count

$lines = @()
$lines += "# Status Update"
$lines += ""
$lines += "Window: last $Days days"
$lines += "Generated: $now"
$lines += "Observations: $total"
$lines += ""

if ($total -eq 0) {
    $lines += "No observations captured in this window."
    $lines += ""
    $lines += "Tip: run ``.\capture-observation.ps1 -Type decision -Note ""..."" `` after meaningful events."
    [System.IO.File]::WriteAllLines($outputPath, $lines)
    Write-Host "Wrote $outputPath (empty window)."
    return
}

$order = @('decision','blocker','dead-end','progress','insight')
foreach ($type in $order) {
    $group = @($entries | Where-Object { $_.Type -eq $type } | Sort-Object Timestamp -Descending)
    if ($group.Count -eq 0) { continue }
    $lines += "## $($type.ToUpper()) ($($group.Count))"
    $lines += ""
    foreach ($e in $group) {
        $date = $e.Timestamp.ToString('yyyy-MM-dd')
        $tagStr = if ($e.Tags -and $e.Tags.Count -gt 0) { " [$(($e.Tags) -join ', ')]" } else { '' }
        $lines += "- $date | $($e.Domain)$tagStr - $($e.Note)"
    }
    $lines += ""
}

$byDomain = @($entries | Group-Object Domain | Sort-Object Count -Descending)
$lines += "## By domain"
$lines += ""
foreach ($g in $byDomain) {
    $lines += "- $($g.Name): $($g.Count)"
}
$lines += ""

[System.IO.File]::WriteAllLines($outputPath, $lines)
Write-Host "Wrote $outputPath with $total observations across $($byDomain.Count) domain(s)."
