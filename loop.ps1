param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('idea','start','promise','wait','done','show')]
    [string]$Action,

    [Parameter(Position=1)]
    [string]$Text,

    [string]$To,
    [string]$By,
    [string]$On,

    [string]$BoardFile = 'open-loops.md',
    [string]$ObsScript = 'capture-observation.ps1'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$boardPath = Join-Path $repoRoot $BoardFile
$obsPath   = Join-Path $repoRoot $ObsScript
$today     = (Get-Date).ToString('yyyy-MM-dd')

if (-not (Test-Path $boardPath)) { throw "Board not found: $boardPath" }

function Log-Obs([string]$type, [string]$note, [string[]]$tags) {
    if (Test-Path $obsPath) {
        & $obsPath -Type $type -Note $note -Domain 'General' -Tags $tags | Out-Null
    }
}

function Read-Board { Get-Content -Path $boardPath -Encoding UTF8 }
function Write-Board([string[]]$lines) {
    Set-Content -Path $boardPath -Value $lines -Encoding UTF8
}

function Get-SectionRange([string[]]$lines, [string]$header) {
    $start = -1; $end = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^##\s+$([regex]::Escape($header))") { $start = $i + 1; continue }
        if ($start -ge 0 -and $lines[$i] -match '^##\s+') { $end = $i; break }
    }
    if ($start -lt 0) { throw "Section not found: $header" }
    @{ Start = $start; End = $end }
}

function Get-SectionItems([string[]]$lines, [string]$header) {
    $r = Get-SectionRange $lines $header
    $items = @()
    for ($i = $r.Start; $i -lt $r.End; $i++) {
        if ($lines[$i] -match '^\s*-\s\[[ x]\]') { $items += [pscustomobject]@{ Index = $i; Line = $lines[$i] } }
    }
    ,$items
}

function Insert-Item([string[]]$lines, [string]$header, [string]$newLine, [int]$cap = 0) {
    $items = Get-SectionItems $lines $header
    $placeholders = @($items | Where-Object { $_.Line -match '_empty_' })
    if ($placeholders.Count -gt 0) {
        $idx = $placeholders[0].Index
        $lines = $lines[0..($idx-1)] + @($newLine) + $lines[($idx+1)..($lines.Count-1)]
        return ,$lines
    }
    if ($cap -gt 0 -and $items.Count -ge $cap) {
        throw "Section '$header' is at cap ($cap). Prune before adding."
    }
    $r = Get-SectionRange $lines $header
    $insertAt = if ($items.Count -gt 0) { $items[-1].Index + 1 } else { $r.Start }
    $before = if ($insertAt -gt 0) { $lines[0..($insertAt-1)] } else { @() }
    $after  = if ($insertAt -lt $lines.Count) { $lines[$insertAt..($lines.Count-1)] } else { @() }
    ,($before + @($newLine) + $after)
}

function Remove-Matching([string[]]$lines, [string]$header, [string]$needle) {
    $items = Get-SectionItems $lines $header
    $hit = $items | Where-Object { $_.Line -like "*$needle*" } | Select-Object -First 1
    if ($null -eq $hit) { return @{ Lines = $lines; Found = $null } }
    $newLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($i -ne $hit.Index) { $newLines += $lines[$i] } }
    @{ Lines = $newLines; Found = $hit.Line }
}

function Prune-DoneOlderThanWeek([string[]]$lines) {
    $cutoff = (Get-Date).AddDays(-7).Date
    $r = Get-SectionRange $lines 'Done this week (rolling -- loop.ps1 auto-prunes entries older than 7 days)'
    $kept = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -lt $r.Start -or $i -ge $r.End) { $kept += $lines[$i]; continue }
        $line = $lines[$i]
        if ($line -match '\b(\d{4}-\d{2}-\d{2})\b') {
            try { $d = [datetime]::ParseExact($Matches[1],'yyyy-MM-dd',$null) } catch { $kept += $line; continue }
            if ($d.Date -ge $cutoff) { $kept += $line }
        } else { $kept += $line }
    }
    ,$kept
}

$lines = Read-Board

switch ($Action) {
    'show' {
        $lines | Write-Output
        return
    }
    'idea' {
        if (-not $Text) { throw "Usage: loop.ps1 idea 'text'" }
        $new = "- [ ] $Text  -- added: $today"
        $lines = Insert-Item $lines 'Active Ideas (cap: 7)' $new 7
        Log-Obs 'insight' "idea: $Text" @('open-loops','idea')
    }
    'start' {
        if (-not $Text) { throw "Usage: loop.ps1 start 'text'" }
        $r = Remove-Matching $lines 'Active Ideas (cap: 7)' $Text
        $lines = $r.Lines
        $new = "- [ ] $Text  -- next: (write a verb)  -- touched: $today"
        $lines = Insert-Item $lines 'In-Flight (cap: 5)' $new 5
        Log-Obs 'progress' "started: $Text" @('open-loops','start')
    }
    'promise' {
        if (-not $Text -or -not $To -or -not $By) { throw "Usage: loop.ps1 promise 'text' -To NAME -By yyyy-mm-dd" }
        $new = "- [ ] $Text  -- to: $To  -- by: $By"
        $lines = Insert-Item $lines 'Promises (no cap, but each needs to and by)' $new
        Log-Obs 'decision' "promised to $To by $By : $Text" @('open-loops','promise')
    }
    'wait' {
        if (-not $Text -or -not $On) { throw "Usage: loop.ps1 wait 'text' -On WHO" }
        $new = "- [ ] $Text  -- on: $On  -- since: $today"
        $lines = Insert-Item $lines 'Waiting On (no cap)' $new
        Log-Obs 'blocker' "waiting on $On : $Text" @('open-loops','wait')
    }
    'done' {
        if (-not $Text) { throw "Usage: loop.ps1 done 'text'" }
        foreach ($section in @('In-Flight (cap: 5)','Promises (no cap, but each needs to and by)','Waiting On (no cap)','Active Ideas (cap: 7)')) {
            $r = Remove-Matching $lines $section $Text
            $lines = $r.Lines
            if ($r.Found) { break }
        }
        $new = "- [x] $Text  -- $today"
        $lines = Insert-Item $lines 'Done this week (rolling -- loop.ps1 auto-prunes entries older than 7 days)' $new
        Log-Obs 'progress' "done: $Text" @('open-loops','done')
    }
}

$lines = Prune-DoneOlderThanWeek $lines
Write-Board $lines
Write-Host "[$Action] ok - open-loops.md updated."
