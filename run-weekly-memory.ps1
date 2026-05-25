param(
    [switch]$Commit,
    [switch]$Push,
    [string]$CommitMessage = "memory: weekly refresh"
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $repoRoot '_personal-root.ps1')
$personalRoot = Get-PersonalMemoryRoot $repoRoot
$personalIsRepo = Test-Path (Join-Path $personalRoot '.git')

Set-Location $repoRoot

Write-Host "Framework repo: $repoRoot"
Write-Host "Personal data : $personalRoot$(if (-not $personalIsRepo) { ' (NOT a git repo)' })"
Write-Host ""

Write-Host "[1/6] Pull latest framework..."
git pull
if ($personalIsRepo) {
    Write-Host "      Pull latest personal data..."
    git -C $personalRoot pull --no-edit
}

Write-Host "[2/6] Run learner..."
.\learn-memory.ps1

if (Test-Path '.\sync-memory.ps1') {
    Write-Host "[2a/6] Cross-machine sync (capture per workspace + active-threads.md)..."
    .\sync-memory.ps1 -NoPull -SinceDays 14
} elseif (Test-Path '.\auto-capture-observations.ps1') {
    Write-Host "[2a/6] Auto-capture observations from Copilot transcripts..."
    .\auto-capture-observations.ps1 -SinceDays 7 -MaxPerRun 25
}

if (Test-Path '.\synthesize-observations.ps1') {
    Write-Host "[2b/6] Synthesize observations..."
    .\synthesize-observations.ps1 -Days 7
}

if (Test-Path '.\prune-observations.ps1') {
    Write-Host "[2c/6] Prune observations older than 90 days..."
    .\prune-observations.ps1 -Days 90
}

if ((Test-Path '.\lint-memory.ps1') -and (Test-Path '.\team-memory')) {
    Write-Host "[3/6] Run team memory lint..."
    .\lint-memory.ps1 -IncludeCanonical
}

Write-Host "[4/6] Stage framework files (shared knowledge, scripts, playbooks)..."
$frameworkFiles = @(
    'README.md',
    'anti-hallucination-protocol.md',
    'thinking-principles.md',
    'decision-framework.md',
    'cognitive-bias-checks.md',
    'exploration-modes.md',
    'gotchas.md',
    'salesforce-debugging.md',
    'project-commands.md',
    'weekly-review-checklist.md',
    'lesson-template.md',
    'docs/memory-adoption-playbook.md',
    'docs/memory-ecosystem-research-2026-05-15.md',
    'docs/copilot-auto-mode.md',
    'lint-memory.ps1',
    'lint-memory.sh',
    'capture-observation.ps1',
    'capture-observation.sh',
    'auto-capture-observations.ps1',
    'auto-capture-observations.sh',
    'synthesize-observations.ps1',
    'synthesize-observations.sh',
    'prune-observations.ps1',
    'sync-memory.ps1',
    'sync-memory.sh',
    'loop.ps1',
    'loop.sh',
    'summon-memory.ps1',
    'summon-memory.sh',
    'learn-memory.ps1',
    'learn-memory.sh',
    'install-scheduled-task.ps1',
    'repair-mojibake.ps1',
    '_personal-root.ps1',
    '.gitattributes',
    '.gitignore'
)

foreach ($f in $frameworkFiles) {
    if (Test-Path $f) { git add $f }
}

if (Test-Path '.\team-memory') { git add team-memory }
if (Test-Path '.\domains')     { git add domains }
if (Test-Path '.\skills')      { git add skills }
if (Test-Path '.\connectors')  { git add connectors }

Write-Host "[5/6] Show staged status..."
git status --short

if ($personalIsRepo) {
    Write-Host ""
    Write-Host "Personal repo status:"
    git -C $personalRoot status --short
}

Write-Host ""
Write-Host "Weekly quality prompts (quick review):"
Write-Host "- Did I update goals.md for this week?"
Write-Host "- Did I log one decision in decision-journal.md?"
Write-Host "- Did I add one anti-hallucination guardrail or verification step?"
Write-Host "- Do top scoreboard items have active guardrails?"
Write-Host "- Did I apply decision-framework.md to one meaningful decision?"
Write-Host "- Did I run cognitive-bias-checks.md before finalizing hard calls?"

if ($Commit) {
    Write-Host "[6/6] Commit framework changes..."
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m $CommitMessage
        if ($Push) {
            Write-Host "Pushing framework to origin/main..."
            git push
        }
    } else {
        Write-Host "No framework changes to commit."
    }

    if ($personalIsRepo) {
        Write-Host "      Commit personal data..."
        git -C $personalRoot add -A
        git -C $personalRoot diff --cached --quiet
        if ($LASTEXITCODE -ne 0) {
            git -C $personalRoot commit -m $CommitMessage
            if ($Push) {
                Write-Host "Pushing personal repo..."
                git -C $personalRoot push
            }
        } else {
            Write-Host "No personal-repo changes to commit."
        }
    }
} else {
    Write-Host "Prepared changes only (no commit)."
    Write-Host "To finish: .\run-weekly-memory.ps1 -Commit -Push"
}
