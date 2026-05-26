<#
.SYNOPSIS
  Render a local, self-contained HTML dashboard from the admission-gate
  scoring log.

.DESCRIPTION
  Reads a JSONL scoring log emitted by score-memory.ps1 -LogTo (PowerShell)
  or score_memory.py --log-to (Python) and writes a single static HTML file
  showing: summary tiles (total, keep%, reject%, recent activity), top
  rejection reasons, contradiction-against-store hits, feedback-loop hits,
  and the 50 most recent decisions.

  Static page only -- no server, no JS framework, no external assets.
  Open the output in any browser (`Start-Process ./admission-gate/dashboard.html`).

  This is the iter-12 "dashboard slice 1": a local audit tool that consumes
  whatever the scorer has been logging. It is NOT a publish target -- the
  log and the dashboard are gitignored. To see live updates, re-run the
  scorer with -LogTo and re-render.

.NOTES
  Run from repo root.
  Exit codes: 0 ok, 2 log missing/malformed.
#>
param(
  [string] $LogPath = "admission-gate/logs/scoring.jsonl",
  [string] $OutPath = "admission-gate/dashboard.html",
  [int]    $RecentCount = 50,
  [int]    $TopReasonCount = 10
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $LogPath)) {
  [Console]::Error.WriteLine("Scoring log not found: $LogPath")
  [Console]::Error.WriteLine("Run the scorer with -LogTo $LogPath first.")
  exit 2
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($line in (Get-Content $LogPath -Encoding UTF8)) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  try {
    $rows.Add(($line | ConvertFrom-Json))
  } catch {
    [Console]::Error.WriteLine("Malformed log line skipped: $line")
  }
}

$total  = $rows.Count
if ($total -eq 0) {
  [Console]::Error.WriteLine("Scoring log is empty: $LogPath")
  exit 2
}
$keep   = ($rows | Where-Object { $_.decision -eq 'keep' }).Count
$reject = $total - $keep
$keepPct   = [math]::Round(100.0 * $keep   / $total, 1)
$rejectPct = [math]::Round(100.0 * $reject / $total, 1)

# Primary rejection reason = first reason fragment (before "; ").
function Get-PrimaryReason([string]$r) {
  if (-not $r) { return '' }
  $first = ($r -split ';\s*')[0]
  # Strip trailing "=-1.x" magnitude so similar reasons group together.
  $first = [regex]::Replace($first, '=-?[0-9.]+', '')
  # Normalize "(contradicts-store=anchor-XX)" / "(feedback-loop=recall-XX)"
  # to "(contradicts-store)" / "(feedback-loop)" so they group.
  $first = [regex]::Replace($first, '\((contradicts-store|feedback-loop)=[^)]+\)', '($1)')
  return $first.Trim()
}

$reasonGroups = @{}
foreach ($row in $rows) {
  if ($row.decision -ne 'reject') { continue }
  $key = Get-PrimaryReason $row.reason
  if (-not $key) { $key = '(no reason captured)' }
  if (-not $reasonGroups.ContainsKey($key)) { $reasonGroups[$key] = 0 }
  $reasonGroups[$key]++
}
$topReasons = $reasonGroups.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $TopReasonCount

# Extract contradiction-against-store and feedback-loop hits with their anchor/recall ids.
$contradicts = New-Object System.Collections.Generic.List[object]
$feedbackLoops = New-Object System.Collections.Generic.List[object]
foreach ($row in $rows) {
  if ($row.reason -match '\(contradicts-store=([^)]+)\)') {
    $contradicts.Add([pscustomobject]@{
      id     = $row.id
      anchor = $Matches[1]
      total  = $row.total
      text   = $row.text
    })
  }
  if ($row.reason -match '\(feedback-loop=([^)]+)\)') {
    $feedbackLoops.Add([pscustomobject]@{
      id     = $row.id
      recall = $Matches[1]
      total  = $row.total
      text   = $row.text
    })
  }
}

# 50 most recent decisions (last N rows in file order, reversed for display).
$recent = $rows | Select-Object -Last $RecentCount
[Array]::Reverse($recent)

function ConvertTo-HtmlSafe([string]$s) {
  if ($null -eq $s) { return '' }
  return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;')
}

$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
$psCount = ($rows | Where-Object { $_.scorer -eq 'ps' }).Count
$pyCount = ($rows | Where-Object { $_.scorer -eq 'py' }).Count

$sb = New-Object System.Text.StringBuilder

[void] $sb.AppendLine('<!doctype html>')
[void] $sb.AppendLine('<html lang="en"><head><meta charset="utf-8">')
[void] $sb.AppendLine('<title>Admission gate dashboard</title>')
[void] $sb.AppendLine('<style>')
[void] $sb.AppendLine('body{font-family:-apple-system,Segoe UI,Helvetica,Arial,sans-serif;margin:24px;max-width:1100px;color:#222;}')
[void] $sb.AppendLine('h1{margin:0 0 4px 0;font-size:22px;}')
[void] $sb.AppendLine('.sub{color:#666;font-size:13px;margin-bottom:24px;}')
[void] $sb.AppendLine('.tiles{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:24px;}')
[void] $sb.AppendLine('.tile{flex:1 1 160px;padding:12px 14px;border:1px solid #ddd;border-radius:6px;background:#fafafa;}')
[void] $sb.AppendLine('.tile .v{font-size:24px;font-weight:600;line-height:1.1;}')
[void] $sb.AppendLine('.tile .k{font-size:12px;color:#555;text-transform:uppercase;letter-spacing:0.04em;}')
[void] $sb.AppendLine('.tile.keep .v{color:#0a7a32;} .tile.reject .v{color:#b22222;}')
[void] $sb.AppendLine('h2{font-size:16px;margin:28px 0 8px 0;padding-bottom:4px;border-bottom:1px solid #eee;}')
[void] $sb.AppendLine('table{border-collapse:collapse;width:100%;font-size:13px;}')
[void] $sb.AppendLine('th,td{padding:6px 8px;border-bottom:1px solid #eee;text-align:left;vertical-align:top;}')
[void] $sb.AppendLine('th{background:#f4f4f4;font-weight:600;}')
[void] $sb.AppendLine('td.keep{color:#0a7a32;font-weight:600;} td.reject{color:#b22222;font-weight:600;}')
[void] $sb.AppendLine('td.num{text-align:right;font-variant-numeric:tabular-nums;}')
[void] $sb.AppendLine('.muted{color:#777;font-size:12px;}')
[void] $sb.AppendLine('code{background:#f4f4f4;padding:1px 4px;border-radius:3px;font-size:12px;}')
[void] $sb.AppendLine('.warn{background:#fff8e1;border-left:3px solid #e6a700;padding:8px 12px;margin:8px 0;font-size:13px;}')
[void] $sb.AppendLine('.empty{color:#888;font-style:italic;font-size:13px;padding:8px 0;}')
[void] $sb.AppendLine('</style></head><body>')

[void] $sb.AppendLine('<h1>Admission gate dashboard</h1>')
[void] $sb.AppendLine("<div class=""sub"">Rendered $now &middot; log: <code>$(ConvertTo-HtmlSafe $LogPath)</code> &middot; PS rows: $psCount &middot; Python rows: $pyCount</div>")

[void] $sb.AppendLine('<div class="tiles">')
[void] $sb.AppendLine("<div class=""tile""><div class=""k"">scored</div><div class=""v"">$total</div></div>")
[void] $sb.AppendLine("<div class=""tile keep""><div class=""k"">kept</div><div class=""v"">$keep <span class=""muted"" style=""font-size:14px;font-weight:400;"">($keepPct%)</span></div></div>")
[void] $sb.AppendLine("<div class=""tile reject""><div class=""k"">rejected</div><div class=""v"">$reject <span class=""muted"" style=""font-size:14px;font-weight:400;"">($rejectPct%)</span></div></div>")
[void] $sb.AppendLine("<div class=""tile""><div class=""k"">contradicts-store</div><div class=""v"">$($contradicts.Count)</div></div>")
[void] $sb.AppendLine("<div class=""tile""><div class=""k"">feedback-loop</div><div class=""v"">$($feedbackLoops.Count)</div></div>")
[void] $sb.AppendLine('</div>')

# Top reasons.
[void] $sb.AppendLine('<h2>Top rejection reasons</h2>')
if ($reasonGroups.Count -eq 0) {
  [void] $sb.AppendLine('<div class="empty">No rejections in this log.</div>')
} else {
  [void] $sb.AppendLine('<table><thead><tr><th>reason</th><th class="num">count</th></tr></thead><tbody>')
  foreach ($r in $topReasons) {
    [void] $sb.AppendLine("<tr><td><code>$(ConvertTo-HtmlSafe $r.Key)</code></td><td class=""num"">$($r.Value)</td></tr>")
  }
  [void] $sb.AppendLine('</tbody></table>')
}

# Contradiction-against-store hits.
[void] $sb.AppendLine('<h2>Contradiction-against-store hits</h2>')
if ($contradicts.Count -eq 0) {
  [void] $sb.AppendLine('<div class="empty">No contradiction-against-store rejections in this log.</div>')
} else {
  [void] $sb.AppendLine('<table><thead><tr><th>candidate</th><th>anchor</th><th class="num">total</th><th>text</th></tr></thead><tbody>')
  foreach ($c in $contradicts) {
    [void] $sb.AppendLine("<tr><td><code>$(ConvertTo-HtmlSafe $c.id)</code></td><td><code>$(ConvertTo-HtmlSafe $c.anchor)</code></td><td class=""num"">$($c.total)</td><td>$(ConvertTo-HtmlSafe $c.text)</td></tr>")
  }
  [void] $sb.AppendLine('</tbody></table>')
}

# Feedback-loop hits.
[void] $sb.AppendLine('<h2>Feedback-loop hits</h2>')
if ($feedbackLoops.Count -eq 0) {
  [void] $sb.AppendLine('<div class="empty">No feedback-loop rejections in this log.</div>')
} else {
  [void] $sb.AppendLine('<table><thead><tr><th>candidate</th><th>recall</th><th class="num">total</th><th>text</th></tr></thead><tbody>')
  foreach ($f in $feedbackLoops) {
    [void] $sb.AppendLine("<tr><td><code>$(ConvertTo-HtmlSafe $f.id)</code></td><td><code>$(ConvertTo-HtmlSafe $f.recall)</code></td><td class=""num"">$($f.total)</td><td>$(ConvertTo-HtmlSafe $f.text)</td></tr>")
  }
  [void] $sb.AppendLine('</tbody></table>')
}

# Recent decisions.
[void] $sb.AppendLine("<h2>Recent decisions (last $RecentCount, newest first)</h2>")
[void] $sb.AppendLine('<table><thead><tr><th>ts</th><th>scorer</th><th>id</th><th>decision</th><th class="num">total</th><th>reason</th><th>text</th></tr></thead><tbody>')
foreach ($row in $recent) {
  $cls = $row.decision
  [void] $sb.AppendLine("<tr><td class=""muted"">$(ConvertTo-HtmlSafe $row.ts)</td><td class=""muted"">$(ConvertTo-HtmlSafe $row.scorer)</td><td><code>$(ConvertTo-HtmlSafe $row.id)</code></td><td class=""$cls"">$(ConvertTo-HtmlSafe $row.decision)</td><td class=""num"">$($row.total)</td><td><code>$(ConvertTo-HtmlSafe $row.reason)</code></td><td>$(ConvertTo-HtmlSafe $row.text)</td></tr>")
}
[void] $sb.AppendLine('</tbody></table>')

[void] $sb.AppendLine('<div class="sub" style="margin-top:32px;">Local-only audit tool. Re-run the scorer with <code>-LogTo</code> / <code>--log-to</code> and re-render to refresh.</div>')
[void] $sb.AppendLine('</body></html>')

$outDir = Split-Path -Parent $OutPath
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
Set-Content -Path $OutPath -Value $sb.ToString() -Encoding UTF8

Write-Host "Dashboard rendered: $OutPath"
Write-Host "  rows=$total  keep=$keep ($keepPct%)  reject=$reject ($rejectPct%)  contradicts=$($contradicts.Count)  feedback-loops=$($feedbackLoops.Count)"
exit 0
