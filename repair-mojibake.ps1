param([string]$Path = 'observations.jsonl')
$ErrorActionPreference = 'Stop'
$full = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) $Path
$text = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
$before = $text.Length

# Common UTF-8-read-as-Win1252 mojibake sequences (composed from Unicode escapes
# to keep this script itself ASCII-safe under PS5.1).
$emdash    = [char]0x00E2 + [char]0x20AC + [char]0x201D   # E2 80 94 mis-decoded
$endash    = [char]0x00E2 + [char]0x20AC + [char]0x201C   # E2 80 93 mis-decoded
$rsquo     = [char]0x00E2 + [char]0x20AC + [char]0x2122   # E2 80 99
$lsquo     = [char]0x00E2 + [char]0x20AC + [char]0x02DC   # E2 80 98
$ldquo     = [char]0x00E2 + [char]0x20AC + [char]0x0153   # E2 80 9C
$rdquo     = [char]0x00E2 + [char]0x20AC                  # E2 80 9D often loses last
$hellip    = [char]0x00E2 + [char]0x20AC + [char]0x00A6   # E2 80 A6
$rarrow    = [char]0x00E2 + [char]0x2020 + [char]0x2019   # E2 86 92
$nbsp      = [char]0x00C2 + [char]0x00A0                  # C2 A0

$text = $text.Replace($emdash,  [string][char]0x2014)
$text = $text.Replace($endash,  [string][char]0x2013)
$text = $text.Replace($rsquo,   "'")
$text = $text.Replace($lsquo,   "'")
$text = $text.Replace($ldquo,   '"')
$text = $text.Replace($rdquo,   '"')
$text = $text.Replace($hellip,  '...')
$text = $text.Replace($rarrow,  '->')
$text = $text.Replace($nbsp,    ' ')

# Stray solitary 'Â' that often appears as artefact
$text = $text.Replace([string][char]0x00C2, '')

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($full, $text, $utf8NoBom)
Write-Host "Repaired mojibake in $Path : $before -> $($text.Length) bytes"
