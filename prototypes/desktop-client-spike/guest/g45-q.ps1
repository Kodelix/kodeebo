# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does a launcher outside the program folder that re-runs the last good installer make the app start after every
# power cut during an update, with nobody reinstalling (round 3, G4.5)?
# Date: 2026-10-18
# Helper for tools/g45.sh, run as cashier over SSH:
#   -what startup-on | startup-off   put / remove the launcher in the cashier's Startup folder
#   -what started                    "yes" once launcher.log has "installer starting" for the current update
#   -what log -n <k>                 last k lines of launcher.log, one line, " || " separated
#   -what logsince -mark <n>         launcher.log lines after line n, " || " separated
#   -what loglines                   line count of launcher.log
#   -what journal                    journal.txt on one line
#   -what msiphase                   for A: last "Action start/ended" line of the oldest MSI log not yet reported
param([string]$rt = 'a', [string]$what = 'log', [int]$n = 5, [int]$mark = 0)
$h = Join-Path $env:LOCALAPPDATA "KodeeboSpikeLauncher\$rt"
$logf = Join-Path $h 'launcher.log'
$su = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\kspike-launcher.cmd'
switch ($what) {
  'startup-on' {
    Set-Content -LiteralPath $su -Encoding ascii -Value "@start `"`" /min powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$h\kspike-launcher.ps1`" -rt $rt"
    "startup entry: $su"
  }
  'startup-off' { Remove-Item -LiteralPath $su -ErrorAction SilentlyContinue; 'startup entry removed' }
  'started' { if ((Test-Path $logf) -and (Get-Content $logf -Tail 3 | Select-String -SimpleMatch 'installer starting')) { 'yes' } else { 'no' } }
  'log' { if (Test-Path $logf) { (Get-Content $logf -Tail $n) -join ' || ' } else { 'no launcher.log' } }
  'logsince' { if (Test-Path $logf) { (Get-Content $logf | Select-Object -Skip $mark) -join ' || ' } else { 'no launcher.log' } }
  'loglines' { if (Test-Path $logf) { (Get-Content $logf).Count } else { 0 } }
  'journal' { if (Test-Path "$h\journal.txt") { (Get-Content "$h\journal.txt") -join ' ' } else { 'no journal' } }
  'msiphase' {
    $f = Get-ChildItem $h -Filter 'msi-*.log' -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
    if (-not $f) { 'no msi log (cut before msiexec logged)' }
    else {
      $l = Get-Content $f.FullName -Encoding Unicode -ErrorAction SilentlyContinue | Where-Object { $_ -match '^Action (start|ended) [0-9:]+: [A-Za-z]+\.' } | Select-Object -Last 1
      if (-not $l) { $l = 'msi log has no Action line yet' }
      "$($f.Name): $l"
      Move-Item $f.FullName "$($f.FullName).seen" -Force
    }
  }
}
