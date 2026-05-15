param(
    [string]$Root = "",
    [switch]$IncludeCanonical
)

$ErrorActionPreference = 'Stop'

if (-not $Root) {
    $Root = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$paths = @(
    (Join-Path $Root 'team-memory\inbox')
)

if ($IncludeCanonical) {
    $paths += (Join-Path $Root 'team-memory\canonical')
}

$requiredFields = @(
    'Domain:',
    'Scope:',
    'What failed:',
    'Guardrail to prevent recurrence:',
    'Evidence:',
    'Confidence:',
    'Last verified date:',
    'Owner:',
    'Date:'
)

$issues = @()
$checked = 0

foreach ($p in $paths) {
    if (-not (Test-Path $p)) { continue }

    $files = Get-ChildItem -Path $p -Filter *.md -File -Recurse
    foreach ($file in $files) {
        if ($file.Name -eq 'README.md') { continue }

        $checked++
        $content = Get-Content $file.FullName -Raw

        if ($content -notmatch '(?m)^##\s+\[(P0|P1|P2)\]') {
            $issues += "[$($file.FullName)] Missing severity heading (## [P0|P1|P2] ...)."
        }

        foreach ($field in $requiredFields) {
            if ($content -notmatch [regex]::Escape($field)) {
                $issues += "[$($file.FullName)] Missing required field: $field"
            }
        }

        $confidenceMatch = [regex]::Match($content, '(?im)^\s*[-*]?\s*confidence:\s*(.+)$')
        if ($confidenceMatch.Success) {
            $val = $confidenceMatch.Groups[1].Value.Trim().ToLower()
            if ($val -notin @('low','medium','high')) {
                $issues += "[$($file.FullName)] Invalid confidence value '$val'. Allowed: low|medium|high."
            }
        }

        $dateFields = @('last verified date', 'date', 're-verify by')
        foreach ($name in $dateFields) {
            $m = [regex]::Matches($content, "(?im)^\\s*[-*]?\\s*$name\\s*:\\s*(.+)$")
            foreach ($x in $m) {
                $value = $x.Groups[1].Value.Trim()
                if (-not $value) { continue }
                if ($value -notmatch '^\\d{4}-\\d{2}-\\d{2}$') {
                    $issues += "[$($file.FullName)] '$name' must be YYYY-MM-DD (found '$value')."
                }
            }
        }
    }
}

Write-Host "Files checked: $checked"
if ($issues.Count -eq 0) {
    Write-Host 'Memory lint passed.'
    exit 0
}

Write-Host "Memory lint found $($issues.Count) issue(s):"
foreach ($i in $issues) {
    Write-Host "- $i"
}

exit 1
