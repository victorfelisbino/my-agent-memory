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

Write-Host "[2/5] Run learner..."
.\learn-memory.ps1

Write-Host "[3/5] Stage weekly memory files..."
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
    'weekly-review-checklist.md'
)

foreach ($f in $filesToStage) {
    if (Test-Path $f) {
        git add $f
    }
}

Write-Host "[4/5] Show staged status..."
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
    Write-Host "[5/5] Commit changes..."
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
