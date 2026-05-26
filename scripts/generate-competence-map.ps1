<#
.SYNOPSIS
  Regenerate docs/competence-map.md from competence-map.yml.

.DESCRIPTION
  Reads competence-map.yml at the repo root, walks each entry's sources to
  compute an evidence panel (file count, total bytes, ## heading count,
  gotcha/lesson markers, most-recent git touch, days since touch), then
  renders docs/competence-map.md grouped by depth tier.

  Honesty enforcement (exits non-zero on any of these):
    - A source path listed under any entry does not exist.
    - An entry with depth: expert has zero evidence (no sources resolve).
    - An entry with depth: expert was last touched 180+ days ago.
    - A forbidden client/project name appears anywhere in competence-map.yml
      (list comes from $env:COMPETENCE_MAP_BANNED_NAMES, comma-separated).

.NOTES
  Run from repo root:  pwsh ./scripts/generate-competence-map.ps1
  Add -Quiet to suppress per-entry trace output.
  Add -CheckOnly to lint without rewriting docs/competence-map.md.
#>
param(
  [string] $YamlPath = "competence-map.yml",
  [string] $OutPath  = "docs/competence-map.md",
  [switch] $Quiet,
  [switch] $CheckOnly
)

$ErrorActionPreference = "Stop"

function Write-Trace([string]$msg) {
  if (-not $Quiet) { Write-Host $msg }
}

# ---------------------------------------------------------------------------
# Minimal YAML parser for the constrained schema we use here.
# Handles only:
#   - list-of-mappings at top level (each entry starts with "- ")
#   - scalar fields "  key: value"
#   - list fields "  key:\n    - item\n    - item"
# Strips inline comments ("# ...") outside of quoted strings.
# Strings may be unquoted or wrapped in double quotes.
# ---------------------------------------------------------------------------
function ConvertFrom-CompetenceYaml {
  param([string[]]$Lines)

  $entries        = New-Object System.Collections.Generic.List[hashtable]
  $current        = $null
  $currentListKey = $null
  $lineNo         = 0

  foreach ($raw in $Lines) {
    $lineNo++
    $line = $raw -replace "`r$", ""

    # Strip pure comment lines and blanks early.
    if ($line.Trim() -eq "")    { continue }
    if ($line.TrimStart().StartsWith("#")) { continue }

    # Strip trailing inline comments (no quoted-string handling — schema
    # explicitly avoids "#" inside values).
    $hashIdx = $line.IndexOf(" #")
    if ($hashIdx -ge 0) { $line = $line.Substring(0, $hashIdx) }
    if ($line.Trim() -eq "") { continue }

    # Start of new entry: "- key: value"
    if ($line -match '^-\s+([a-zA-Z_][\w-]*)\s*:\s*(.*)$') {
      if ($current) { [void]$entries.Add($current) }
      $current = [ordered]@{}
      $current[$matches[1]] = ($matches[2].Trim()).Trim('"')
      $currentListKey = $null
      continue
    }

    if (-not $current) {
      throw "Line $lineNo`: content before first entry: '$line'"
    }

    # List header: "  key:"
    if ($line -match '^\s{2,}([a-zA-Z_][\w-]*)\s*:\s*$') {
      $currentListKey = $matches[1]
      $current[$currentListKey] = New-Object System.Collections.Generic.List[string]
      continue
    }

    # List item: "    - value"
    if ($currentListKey -and ($line -match '^\s{2,}-\s+(.+)$')) {
      [void]$current[$currentListKey].Add(($matches[1].Trim()).Trim('"'))
      continue
    }

    # Scalar: "  key: value"
    if ($line -match '^\s{2,}([a-zA-Z_][\w-]*)\s*:\s+(.+)$') {
      $current[$matches[1]] = ($matches[2].Trim()).Trim('"')
      $currentListKey = $null
      continue
    }

    throw "Line $lineNo`: unrecognized YAML construct: '$line'"
  }

  if ($current) { [void]$entries.Add($current) }
  return ,$entries
}

# ---------------------------------------------------------------------------
# Resolve paths relative to repo root, regardless of where the script is run.
# ---------------------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
Set-Location $repoRoot

if (-not (Test-Path $YamlPath)) { throw "Missing $YamlPath" }

# ---------------------------------------------------------------------------
# Banned-names lint.
# Comma-separated list in $env:COMPETENCE_MAP_BANNED_NAMES (e.g. "Acme,Globex").
# Public file by definition has no client names; this is a belt + suspenders.
# ---------------------------------------------------------------------------
$rawYaml = Get-Content $YamlPath -Raw -Encoding UTF8
$bannedRaw = $env:COMPETENCE_MAP_BANNED_NAMES
$banned = @()
if ($bannedRaw) {
  $banned = $bannedRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}
$bannedHits = @()
foreach ($name in $banned) {
  if ($rawYaml -match [regex]::Escape($name)) {
    $bannedHits += $name
  }
}
if ($bannedHits.Count -gt 0) {
  Write-Error "competence-map.yml contains banned client/project names: $($bannedHits -join ', ')"
  exit 2
}

# ---------------------------------------------------------------------------
# Parse YAML.
# ---------------------------------------------------------------------------
$entries = ConvertFrom-CompetenceYaml -Lines (Get-Content $YamlPath -Encoding UTF8)
Write-Trace "Parsed $($entries.Count) entries from $YamlPath"

# ---------------------------------------------------------------------------
# Compute evidence per entry.
# ---------------------------------------------------------------------------
function Get-LastGitTouchIso([string]$path) {
  try {
    $out = git log -1 --format=%cI -- $path 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) { return $null }
    return $out.Trim()
  } catch {
    return $null
  }
}

$violations = New-Object System.Collections.Generic.List[string]
$now = Get-Date

foreach ($e in $entries) {
  $sources = $e.sources
  if (-not $sources) { $sources = @() }

  $fileCount     = 0
  $totalBytes    = 0
  $headingCount  = 0
  $markerCount   = 0
  $lastTouch     = $null
  $missing       = @()

  foreach ($src in $sources) {
    if (-not (Test-Path $src)) {
      $missing += $src
      continue
    }
    $fi = Get-Item $src
    $fileCount += 1
    $totalBytes += $fi.Length

    $text = Get-Content $src -Raw -Encoding UTF8
    $headingCount += ([regex]::Matches($text, '(?m)^##\s')).Count
    $markerCount  += ([regex]::Matches($text, '(?im)\b(gotcha|lesson)\s*:')).Count

    $iso = Get-LastGitTouchIso $src
    if ($iso) {
      $dt = [DateTime]::Parse($iso)
      if (-not $lastTouch -or $dt -gt $lastTouch) { $lastTouch = $dt }
    }
  }

  $e.evidence_file_count = $fileCount
  $e.evidence_bytes      = $totalBytes
  $e.evidence_headings   = $headingCount
  $e.evidence_markers    = $markerCount
  $e.evidence_total      = ($fileCount + $headingCount + $markerCount)
  $e.last_touch          = $lastTouch
  $e.missing_sources     = $missing
  $e.days_since_touch    = if ($lastTouch) { [int]($now - $lastTouch).TotalDays } else { $null }

  # Honesty enforcement.
  if ($missing.Count -gt 0) {
    foreach ($m in $missing) {
      $violations.Add("$($e.id): missing source path '$m'")
    }
  }
  if ($e.depth -eq 'expert') {
    if ($e.evidence_total -eq 0) {
      $violations.Add("$($e.id): depth=expert but zero evidence")
    }
    if ($e.days_since_touch -ne $null -and $e.days_since_touch -gt 180) {
      $violations.Add("$($e.id): depth=expert but last touched $($e.days_since_touch) days ago")
    }
  }
}

if ($violations.Count -gt 0) {
  Write-Error "Honesty violations in competence-map.yml:`n  - $($violations -join "`n  - ")"
  exit 3
}

# ---------------------------------------------------------------------------
# Apply dormancy override: depth=expert/working/explore + >90d untouched -> dormant in render.
# (We do not mutate $e.depth — we set $e.rendered_depth so the YAML stays
# author-truth and the page reflects time.)
# ---------------------------------------------------------------------------
foreach ($e in $entries) {
  $rd = $e.depth
  if ($e.days_since_touch -ne $null -and $e.days_since_touch -gt 90 -and $rd -ne 'dormant') {
    $rd = 'dormant'
  }
  $e.rendered_depth = $rd
}

# ---------------------------------------------------------------------------
# Render markdown grouped by depth tier.
# ---------------------------------------------------------------------------
$tierOrder = @('expert', 'working', 'explore', 'dormant')
$tierLabel = @{
  expert  = 'Expert'
  working = 'Working'
  explore = 'Explore'
  dormant = 'Dormant (no touch in 90+ days)'
}

$totals = @{}
foreach ($t in $tierOrder) { $totals[$t] = 0 }
foreach ($e in $entries)   { $totals[$e.rendered_depth] += 1 }

$generated = (Get-Date).ToString("yyyy-MM-dd HH:mm 'local'")

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Competence map')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> What this brain claims to know, at what depth, with what evidence. Generated by [`scripts/generate-competence-map.ps1`](https://github.com/victorfelisbino/my-agent-memory/blob/main/scripts/generate-competence-map.ps1) from [`competence-map.yml`](https://github.com/victorfelisbino/my-agent-memory/blob/main/competence-map.yml). Depth is author-set; the script refuses to render `expert` claims without backing evidence.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine("**Generated:** $generated  |  **Entries:** $($entries.Count)  |  **Expert:** $($totals['expert'])  |  **Working:** $($totals['working'])  |  **Explore:** $($totals['explore'])  |  **Dormant:** $($totals['dormant'])")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Only the shared scope is published. Personal-only entries (in the sibling personal repo) never appear on this page.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')

foreach ($t in $tierOrder) {
  $bucket = $entries | Where-Object { $_.rendered_depth -eq $t } | Sort-Object { $_.name }
  [void]$sb.AppendLine("## $($tierLabel[$t])")
  [void]$sb.AppendLine('')
  if (-not $bucket -or $bucket.Count -eq 0) {
    [void]$sb.AppendLine('_None._')
    [void]$sb.AppendLine('')
    continue
  }

  [void]$sb.AppendLine('| Domain | Scope | Evidence | Last touch | Sources | Related |')
  [void]$sb.AppendLine('|---|---|---|---|---|---|')
  foreach ($e in $bucket) {
    $touch = if ($e.last_touch) {
      "$($e.last_touch.ToString('yyyy-MM-dd')) ($($e.days_since_touch)d ago)"
    } else {
      '_never_'
    }
    $evidence = "files: $($e.evidence_file_count) | headings: $($e.evidence_headings) | markers: $($e.evidence_markers) | ~$([math]::Round($e.evidence_bytes / 1024, 1)) KB"
    $srcList = if ($e.sources -and $e.sources.Count -gt 0) {
      ($e.sources | ForEach-Object { "``$_``" }) -join '<br>'
    } else { '_none_' }
    $relList = if ($e.related -and $e.related.Count -gt 0) {
      ($e.related | ForEach-Object { "``$_``" }) -join ', '
    } else { '—' }
    $scopeBadge = if ($e.scope) { $e.scope } else { 'shared' }

    [void]$sb.AppendLine("| **$($e.name)**<br>_$($e.description)_ | $scopeBadge | $evidence | $touch | $srcList | $relList |")
  }
  [void]$sb.AppendLine('')
}

[void]$sb.AppendLine('---')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## How to read this page')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('- **Depth** is author-set in `competence-map.yml`. The generator refuses to render `expert` entries that have zero evidence or have not been touched in 180+ days.')
[void]$sb.AppendLine('- **Dormant** is computed: any entry not touched in 90+ days renders as dormant regardless of author-set depth, so a stale brain looks stale.')
[void]$sb.AppendLine('- **Evidence** counts are mechanical: file count, `## ` heading count, `gotcha:` / `lesson:` markers, total bytes. They measure substance, not quality.')
[void]$sb.AppendLine('- **Scope** = `shared` on this page. `personal-only` entries live in the sibling `my-agent-memory-personal` repo and never publish here.')
[void]$sb.AppendLine('- **Two-repo merge** (sibling personal repo) and **automatic regeneration** are roadmap follow-ups (Wave 2.5 follow-up section).')
[void]$sb.AppendLine('')

if ($CheckOnly) {
  $new = $sb.ToString()
  if (-not (Test-Path $OutPath)) {
    [Console]::Error.WriteLine("CheckOnly: $OutPath does not exist. Run the generator and commit the result.")
    exit 4
  }
  $current = Get-Content $OutPath -Raw -Encoding UTF8

  # Normalize time-dependent bits before comparing so the check is stable
  # across days and across CI vs local clocks.
  #   - "**Generated:** ..." header line varies per run.
  #   - "(Nd ago)" elapsed-time stamps tick over each day.
  function Normalize-Map([string]$s) {
    $s = [regex]::Replace($s, '(?m)^\*\*Generated:\*\*.*$', '**Generated:** _normalized_')
    $s = [regex]::Replace($s, '\(\d+d ago\)', '(Nd ago)')
    # Collapse CRLF/LF differences so check works on both Windows and Linux.
    $s = $s -replace "`r`n", "`n"
    return $s.TrimEnd()
  }

  $nNew     = Normalize-Map $new
  $nCurrent = Normalize-Map $current

  if ($nNew -ne $nCurrent) {
    [Console]::Error.WriteLine("CheckOnly: $OutPath is out of date. Run scripts/generate-competence-map.ps1 and commit the result.")
    exit 4
  }
  Write-Trace "CheckOnly: $OutPath is up to date ($($sb.Length) chars)"
  exit 0
}

# Write atomically.
$tmp = "$OutPath.tmp"
$sb.ToString() | Set-Content -Path $tmp -Encoding UTF8 -NoNewline
Move-Item -Force $tmp $OutPath

Write-Trace "Wrote $OutPath ($($sb.Length) chars)"
