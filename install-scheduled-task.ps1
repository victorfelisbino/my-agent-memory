param(
    [string]$TaskName,
    [string]$Time = '09:00',
    [ValidateSet('Daily','Weekly')]
    [string]$Frequency = 'Weekly',
    [string]$DayOfWeek = 'Monday',
    [switch]$Push,
    [switch]$DailySync,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

# DailySync convenience preset: registers a daily task that runs sync-memory.ps1 -Commit -Push
if ($DailySync) {
    if (-not $TaskName) { $TaskName = 'MemoryDailySync' }
    $Frequency = 'Daily'
    $Push = $true
} elseif (-not $TaskName) {
    $TaskName = 'MemoryWeeklyRefresh'
}

if ($Uninstall) {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed scheduled task: $TaskName"
    } else {
        Write-Host "No scheduled task named $TaskName found."
    }
    return
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($DailySync) {
    $runner = Join-Path $repoRoot 'sync-memory.ps1'
} else {
    $runner = Join-Path $repoRoot 'run-weekly-memory.ps1'
}

if (-not (Test-Path $runner)) {
    throw "Runner not found at $runner"
}

$args = '-Commit'
if ($Push) { $args += ' -Push' }

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$runner`" $args" `
    -WorkingDirectory $repoRoot

if ($Frequency -eq 'Daily') {
    $trigger = New-ScheduledTaskTrigger -Daily -At $Time
} else {
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
}

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Automated memory refresh: $(Split-Path -Leaf $runner) $args" | Out-Null

Write-Host "Installed scheduled task: $TaskName"
Write-Host "Frequency: $Frequency at $Time$(if ($Frequency -eq 'Weekly') { " on $DayOfWeek" } else { '' })"
Write-Host "Runner: $runner $args"
Write-Host ""
Write-Host "Manage with:"
Write-Host "  Get-ScheduledTask -TaskName $TaskName"
Write-Host "  Start-ScheduledTask -TaskName $TaskName    # run once now"
Write-Host "  .\install-scheduled-task.ps1 -Uninstall"
