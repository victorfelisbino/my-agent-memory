param(
    [switch]$Commit,
    [switch]$Push,
    [string]$CommitMessage = "memory: weekly refresh"
)

$ErrorActionPreference = 'Stop'
$repoDir = "$env:APPDATA\Code\User\memories"

Set-Location $repoDir

Write-Host "[1/5] Pull latest memory..."
git pull

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

Write-Host "[4/6] Stage weekly memory files..."
$filesToStage = @(
    'memory-scoreboard.md',
    'memory-top-patterns.md',
    'gotchas.md',
    'salesforce-debugging.md',
    'project-commands.md',
    'README.md',
    'anti-hallucination-protocol.md',
    'thinking-principles.md',
    'decision-framework.md',
    'cognitive-bias-checks.md',
    'exploration-modes.md',
    'goals.md',
    'performance-map.md',
    'decision-journal.md',
    'weekly-review-checklist.md',
    'lesson-template.md',
    'memory-adoption-playbook.md',
    'memory-ecosystem-research-2026-05-15.md',
    'lint-memory.ps1',
    'lint-memory.sh',
    'capture-observation.ps1',
    'capture-observation.sh',
    'auto-capture-observations.ps1',
    'auto-capture-observations.sh',
    'synthesize-observations.ps1',
    'synthesize-observations.sh',
    'prune-observations.ps1',
    'observations.jsonl',
    'status-update.md',
    'sync-memory.ps1',
    'sync-memory.sh',
    'active-threads.md',
    'open-loops.md',
    'loop.ps1',
    'loop.sh',
    '.gitattributes'
)

foreach ($f in $filesToStage) {
    if (Test-Path $f) {
        git add $f
    }
}

if (Test-Path '.\team-memory') {
    git add team-memory
}

Write-Host "[5/6] Show staged status..."
git status --short

Write-Host ""
Write-Host "Weekly quality prompts (quick review):"
Write-Host "- Did I update goals.md for this week?"
Write-Host "- Did I log one decision in decision-journal.md?"
Write-Host "- Did I add one anti-hallucination guardrail or verification step?"
Write-Host "- Do top scoreboard items have active guardrails?"
Write-Host "- Did I apply decision-framework.md to one meaningful decision?"
Write-Host "- Did I run cognitive-bias-checks.md before finalizing hard calls?"

if ($Commit) {
    Write-Host "[6/6] Commit changes..."
    git commit -m $CommitMessage

    if ($Push) {
        Write-Host "Pushing to origin/main..."
        git push
    } else {
        Write-Host "Commit created. Use 'git push' when ready."
    }
} else {
    Write-Host "Prepared changes only (no commit)."
    Write-Host "To finish: .\run-weekly-memory.ps1 -Commit -Push"
}
