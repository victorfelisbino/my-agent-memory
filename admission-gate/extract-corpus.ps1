<#
.SYNOPSIS
  Extract atomic memory items from real .md memory files into a JSONL corpus.

.DESCRIPTION
  Walks the repo (or any -Root) looking for markdown files and pulls each
  top-level bullet ("- ..." line, outside code fences) as one memory item.
  Strips bold-wrapped lead-ins like "- **Title**: body" so the scored text
  matches what an agent would actually store. Writes JSONL with fields
  { id, text, source } suitable for ./score-memory.ps1 -Unlabeled.

  This is NOT a labeled fixture. There is no ground truth. Use it to look
  at the scorer's behavior on real memory: distribution, would-be rejects,
  obvious false positives. Read the output before trusting the numbers.

.PARAMETER Root
  Folder to scan. Defaults to the repo root.

.PARAMETER Out
  Output JSONL path. Defaults to admission-gate/fixtures/real-memory.jsonl.

.PARAMETER MinLength
  Skip bullets shorter than this many characters (default 20) — drops
  noise like "- TBD" or single-word checklist items.

.PARAMETER ExcludePatterns
  Regex patterns (matched against the relative file path) to skip. By default
  templates, READMEs, scoreboard/status pages, and research notes are skipped
  because they are not memory items.

.NOTES
  Exit codes: 0 ok, 2 root missing.
#>
param(
  [string]   $Root            = "",
  [string]   $Out             = "admission-gate/fixtures/real-memory.jsonl",
  [int]      $MinLength       = 20,
  [string[]] $ExcludePatterns = @(
    'README\.md$',
    'CONTRIBUTING\.md$',
    'team-memory/templates/',
    'skills/templates/',
    'admission-gate/fixtures/',
    'admission-gate/README\.md$',
    'memory-ecosystem-research',
    'memory-scoreboard\.md$',
    'status-update\.md$',
    'lesson-template\.md$',
    'weekly-review-checklist\.md$',
    # docs/ is project documentation (status, roadmap, scope) -- not memory.
    '^docs/'
  )
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
if (-not $Root) { $Root = $repoRoot }
if (-not (Test-Path $Root)) {
  [Console]::Error.WriteLine("Root not found: $Root")
  exit 2
}

$Root = (Resolve-Path $Root).Path
Set-Location $repoRoot

$files = Get-ChildItem -Path $Root -Recurse -File -Filter '*.md' |
  Where-Object {
    $rel = $_.FullName.Substring($Root.Length).TrimStart('\','/').Replace('\','/')
    $skip = $false
    foreach ($p in $ExcludePatterns) { if ($rel -match $p) { $skip = $true; break } }
    -not $skip
  }

$items   = New-Object System.Collections.Generic.List[object]
$counter = 0

foreach ($f in $files) {
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\','/').Replace('\','/')
  $inFence = $false
  $lineNo  = 0
  foreach ($raw in Get-Content -LiteralPath $f.FullName -Encoding UTF8) {
    $lineNo++
    if ($raw -match '^\s*```') { $inFence = -not $inFence; continue }
    if ($inFence) { continue }

    # Top-level bullet only (0-2 leading spaces). Skip deeply nested ones —
    # they are usually sub-points of the parent and not atomic on their own.
    if ($raw -notmatch '^(\s{0,2})-\s+(.+)$') { continue }
    $body = $Matches[2].Trim()

    # Skip task-list markers' brackets but keep the content.
    $body = $body -replace '^\[\s?[xX ]?\s?\]\s*',''

    # Strip a leading "**Title**:" or "**Title** —" so we score the actual
    # rule, not the heading.
    if ($body -match '^\*\*([^*]+)\*\*\s*[:\-–—]\s*(.+)$') {
      $body = "$($Matches[1]): $($Matches[2])".Trim()
    }

    # Drop trailing markdown noise (links to anchors, trailing periods are fine).
    $body = $body.Trim()
    if ($body.Length -lt $MinLength) { continue }

    # Skip heading-only sub-bullets (iter 7): a short line ending in ":" with
    # no content after is a section header, not a memory. Iter 6 surfaced
    # this when the heading-only scorer rule started rejecting 22 such
    # bullets on the real corpus; the right fix is to not emit them in the
    # first place. Keep ":" mid-text intact (only matches trailing colons).
    if ($body -match '^.{1,80}:\s*$') { continue }

    $counter++
    $items.Add([pscustomobject]@{
      id     = "real-$counter"
      text   = $body
      source = "$rel`:$lineNo"
    })
  }
}

$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# Write JSONL with LF line endings so it matches the other fixture and
# stays platform-stable on CI.
$sb = New-Object System.Text.StringBuilder
foreach ($it in $items) {
  $json = $it | ConvertTo-Json -Compress
  [void] $sb.Append($json)
  [void] $sb.Append("`n")
}
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path -Parent $Out)).Path + "/" + (Split-Path -Leaf $Out), $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

Write-Host "Extracted $($items.Count) bullets from $($files.Count) markdown files"
Write-Host "  root  : $Root"
Write-Host "  out   : $Out"
exit 0
