# Build a Matt grill questionnaire from a JSON payload.
# Usage: powershell.exe -File scripts/build-questionnaire.ps1 -Data <payload.json> [-Out <file.html>]
#
# This script only splices text: it never validates the payload and never opens a
# browser. Payload rules live in the renderer, opening lives with the agent.
# Windows PowerShell 5.1 syntax only — see docs/adr/0001-only-out-of-the-box-runtimes.md.
param(
  [Parameter(Mandatory = $true)][string]$Data,
  [string]$Out
)

$ErrorActionPreference = 'Stop'

$template = Join-Path $PSScriptRoot '../assets/questionnaire-template.html'
$html = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $template))

# In valid JSON '<' can only occur inside a string, so replacing every one of them
# is safe and stops the payload from closing the <script> element early.
# 0x5C is a backslash; built this way so the six-character JSON escape is unambiguous.
$escape = [string][char]0x5C + 'u003c'
$json = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Data)).Trim().Replace('<', $escape)

$openTag = '<script id="questionnaire-data" type="application/json">'
$start = $html.IndexOf($openTag)
if ($start -lt 0) { throw "template marker not found in $template" }
$bodyStart = $start + $openTag.Length
$end = $html.IndexOf('</script>', $bodyStart)
if ($end -lt 0) { throw "template data block is never closed in $template" }

$result = $html.Substring(0, $bodyStart) + "`n" + $json + "`n" + $html.Substring($end)

if (-not $Out) {
  # The PID stops two builds in the same second from overwriting each other, and
  # unlike a millisecond stamp it cannot collide at all: one build is one process.
  # The macOS script names its files exactly the same way.
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $Out = Join-Path ([System.IO.Path]::GetTempPath()) "grill-questionnaire-$stamp-$PID.html"
}
[System.IO.File]::WriteAllText($Out, $result, (New-Object System.Text.UTF8Encoding $false))
$Out

# The path goes out before the launcher runs, and a launcher that fails must not
# change the exit status: the file is already built and its path is what matters.
try { Start-Process -FilePath $Out } catch { Write-Warning 'could not open a browser; the path above is ready to use' }
