# PROTOTYPE - NOT FOR PRODUCTION
# Question: Do A (Compose Desktop) and B (Electron) render and accept Egyptian Arabic correctly on Windows 10 22H2 (G3, S6/S46, OQ22)?
# Date: 2026-10-17
# Lists Application-log events of the last N minutes that mention the spike apps or Java (crash diagnosis). Run as admin.
param([int]$minutes = 30)
$ErrorActionPreference = 'Continue'
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = (Get-Date).AddMinutes(-$minutes) } -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -match 'Kodeebo|java|jvm|\.exe' } | Select-Object -First 8 |
  ForEach-Object { '{0:HH:mm:ss} id={1} {2}' -f $_.TimeCreated, $_.Id, (($_.Message -replace '\s+', ' ').Substring(0, [Math]::Min(500, $_.Message.Length))) }
"done"
