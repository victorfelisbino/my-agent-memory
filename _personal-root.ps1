# Resolves the path to the personal-memory data repo.
# Dot-source this file from any script that reads/writes personal data:
#   . (Join-Path $repoRoot '_personal-root.ps1')
#   $personalRoot = Get-PersonalMemoryRoot $repoRoot
#
# Resolution order:
#   1. $env:AGENT_MEMORY_PERSONAL (if set and the path exists)
#   2. Sibling directory of the framework repo named 'my-agent-memory-personal'
#   3. The framework repo itself (legacy fallback; for users who haven't split yet)
function Get-PersonalMemoryRoot {
    param([Parameter(Mandatory=$true)][string]$FrameworkRoot)

    if ($env:AGENT_MEMORY_PERSONAL -and (Test-Path $env:AGENT_MEMORY_PERSONAL)) {
        return (Resolve-Path $env:AGENT_MEMORY_PERSONAL).Path
    }
    $parent = Split-Path -Parent $FrameworkRoot
    if ($parent) {
        $sibling = Join-Path $parent 'my-agent-memory-personal'
        if (Test-Path $sibling) { return (Resolve-Path $sibling).Path }
    }
    return $FrameworkRoot
}
