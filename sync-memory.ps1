param(
    [string]$WorkspaceStorageRoot = "$env:APPDATA\Code\User\workspaceStorage",
    [string]$LogFile = 'observations.jsonl',
    [string]$ThreadsFile = 'active-threads.md',
    [int]$SinceDays = 14,
    [int]$MaxPerWorkspace = 25,
    [string]$MachineTag,
    [switch]$NoPull,
    [switch]$Commit,
    [switch]$Push,
    [string]$CommitMessage
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot
. (Join-Path $repoRoot '_personal-root.ps1')
$personalRoot = Get-PersonalMemoryRoot $repoRoot
$personalIsRepo = Test-Path (Join-Path $personalRoot '.git')

if (-not $MachineTag) { $MachineTag = $env:COMPUTERNAME }
if (-not $MachineTag) { $MachineTag = 'unknown-machine' }
$MachineTag = ($MachineTag -replace '[^A-Za-z0-9._-]', '-').ToLower()

function Write-Step([string]$msg) { Write-Host "[sync-memory] $msg" }
Write-Step "framework: $repoRoot"
Write-Step "personal : $personalRoot$(if (-not $personalIsRepo) { ' (NOT a git repo - data will not sync across machines!)' })"

# --- 1. Pull latest from other machines (relies on .gitattributes union merge for observations.jsonl) ---
if (-not $NoPull) {
    if ($personalIsRepo) {
        Write-Step "git pull (personal repo)..."
        git -C $personalRoot pull --no-edit
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git pull on personal repo failed (exit $LASTEXITCODE). Resolve and re-run, or pass -NoPull."
            return
        }
    } else {
        Write-Step "personal data dir is not a git repo - skipping pull"
    }
}

# --- 2. Enumerate local workspaces with Copilot transcripts ---
if (-not (Test-Path $WorkspaceStorageRoot)) {
    Write-Warning "Workspace storage root not found: $WorkspaceStorageRoot"
    return
}

function Resolve-WorkspaceName([string]$workspaceDir) {
    $wsJson = Join-Path $workspaceDir 'workspace.json'
    if (-not (Test-Path $wsJson)) { return $null }
    try {
        $obj = Get-Content $wsJson -Raw -Encoding UTF8 | ConvertFrom-Json
        $folder = $obj.folder
        if (-not $folder) { return $null }
        # folder is a URI like file:///c%3A/path/to/MyProject
        $decoded = [System.Uri]::UnescapeDataString($folder)
        $leaf = Split-Path -Leaf ($decoded -replace '^file:///', '' -replace '/', '\')
        if (-not $leaf) { return $null }
        return ($leaf -replace '[^A-Za-z0-9._-]', '-').ToLower()
    } catch { return $null }
}

$workspaces = @()
foreach ($wsDir in Get-ChildItem $WorkspaceStorageRoot -Directory -ErrorAction SilentlyContinue) {
    $tx = Join-Path $wsDir.FullName 'GitHub.copilot-chat\transcripts'
    if (-not (Test-Path $tx)) { continue }
    $name = Resolve-WorkspaceName $wsDir.FullName
    if (-not $name) { $name = $wsDir.Name.Substring(0, [Math]::Min(12, $wsDir.Name.Length)) }
    $workspaces += [pscustomobject]@{ Name = $name; TranscriptDir = $tx }
}

Write-Step "found $($workspaces.Count) workspace(s) with Copilot transcripts on $MachineTag"

# --- 3. Capture per workspace, attributed with machine + workspace tags ---
$captureScript = Join-Path $repoRoot 'auto-capture-observations.ps1'
$logPath = Join-Path $personalRoot $LogFile
if (-not (Test-Path $captureScript)) {
    Write-Warning "auto-capture-observations.ps1 not found in framework repo. Aborting capture phase."
} else {
    foreach ($ws in $workspaces) {
        $tags = @("machine:$MachineTag", "workspace:$($ws.Name)")
        Write-Step "capturing $($ws.Name) ..."
        & $captureScript -TranscriptDir $ws.TranscriptDir -SinceDays $SinceDays -MaxPerRun $MaxPerWorkspace -ExtraTags $tags -LogFile $logPath
    }
}

# --- 4. Build active-threads.md: cross-machine "what am I working on" view ---
$cutoff = (Get-Date).AddDays(-$SinceDays)

$entries = @()
if (Test-Path $logPath) {
    foreach ($line in Get-Content $logPath -Encoding UTF8) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try {
            $obj = $line | ConvertFrom-Json -ErrorAction Stop
        } catch { continue }
        $ts = [datetime]::MinValue
        if ($obj.timestamp) { [void][datetime]::TryParse([string]$obj.timestamp, [ref]$ts) }
        if ($ts -eq [datetime]::MinValue -or $ts -lt $cutoff) { continue }

        $machine = $null; $workspace = $null
        if ($obj.tags) {
            foreach ($t in $obj.tags) {
                if ($t -like 'machine:*')   { $machine   = $t.Substring(8) }
                if ($t -like 'workspace:*') { $workspace = $t.Substring(10) }
            }
        }
        if (-not $workspace) { $workspace = '(unattributed)' }
        if (-not $machine)   { $machine   = '?' }

        $entries += [pscustomobject]@{
            Timestamp = $ts
            Type      = [string]$obj.type
            Domain    = [string]$obj.domain
            Machine   = $machine
            Workspace = $workspace
            Note      = [string]$obj.note
        }
    }
}

$groups = $entries | Group-Object Workspace | ForEach-Object {
    $latest = ($_.Group | Sort-Object Timestamp -Descending | Select-Object -First 1).Timestamp
    [pscustomobject]@{
        Workspace = $_.Name
        Count     = $_.Count
        Latest    = $latest
        Machines  = ($_.Group.Machine | Sort-Object -Unique) -join ', '
        Items     = $_.Group | Sort-Object Timestamp -Descending
    }
} | Sort-Object Latest -Descending

$now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$md  = @()
$md += '# Active Threads (cross-machine)'
$md += ''
$md += "Updated: $now"
$md += "Window: last $SinceDays days"
$md += "Total observations in window: $($entries.Count)"
$md += "Workspaces with activity: $($groups.Count)"
$md += "Machines seen: $((($entries.Machine | Sort-Object -Unique) -join ', '))"
$md += ''
$md += 'Each section is one project/workspace, ordered by most recent activity.'
$md += 'Use this to remember what you have going where.'
$md += ''

if ($groups.Count -eq 0) {
    $md += '_No attributed activity yet. Run on each machine, then `git push`._'
} else {
    foreach ($g in $groups) {
        $md += "## $($g.Workspace)"
        $md += "- Last activity: $($g.Latest.ToString('yyyy-MM-dd HH:mm')) on $($g.Machines)"
        $md += "- Observations in window: $($g.Count)"
        $byType = $g.Items | Group-Object Type | Sort-Object Count -Descending
        $typeLine = ($byType | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '
        if ($typeLine) { $md += "- By type: $typeLine" }
        $md += ''
        $md += '### Recent signals'
        foreach ($it in ($g.Items | Select-Object -First 6)) {
            $note = $it.Note
            if ($note.Length -gt 160) { $note = $note.Substring(0,157) + '...' }
            $md += "- $($it.Timestamp.ToString('yyyy-MM-dd')) [$($it.Type)] ($($it.Machine)) $note"
        }
        $md += ''
    }
}

$threadsPath = Join-Path $personalRoot $ThreadsFile
Set-Content -Path $threadsPath -Value ($md -join "`n") -Encoding UTF8
Write-Step "wrote $ThreadsFile ($($groups.Count) workspace group(s))"

# --- 5. Optional commit + push (against the PERSONAL repo, not the framework repo) ---
if ($Commit) {
    if (-not $personalIsRepo) {
        Write-Step "personal data dir is not a git repo - skipping commit/push"
    } else {
        if (-not $CommitMessage) {
            $CommitMessage = "memory: sync from $MachineTag ($($groups.Count) ws, $($entries.Count) obs)"
        }
        git -C $personalRoot add $LogFile $ThreadsFile 2>$null
        git -C $personalRoot diff --cached --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Step "no changes to commit"
        } else {
            git -C $personalRoot commit -m $CommitMessage
            if ($Push) {
                Write-Step "pushing personal repo..."
                git -C $personalRoot push
                if ($LASTEXITCODE -ne 0) {
                    Write-Step "push failed; pulling and retrying once..."
                    git -C $personalRoot pull --no-edit
                    git -C $personalRoot push
                }
            }
        }
    }
}

Write-Step "done. Open active-threads.md to see everything across machines."
