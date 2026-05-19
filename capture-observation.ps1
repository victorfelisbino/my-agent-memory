param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('decision','blocker','progress','dead-end','insight')]
    [string]$Type,

    [Parameter(Mandatory=$true)]
    [string]$Note,

    [ValidateSet('General','Salesforce','MuleSoft')]
    [string]$Domain = 'General',

    [string[]]$Tags = @(),

    [string]$LogFile = 'observations.jsonl'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $repoRoot $LogFile

$entry = [ordered]@{
    timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssK')
    type      = $Type
    domain    = $Domain
    tags      = $Tags
    note      = $Note
}

$json = ($entry | ConvertTo-Json -Compress -Depth 5)
Add-Content -Path $logPath -Value $json -Encoding UTF8

Write-Host "[$Type] $Domain :: $Note"
