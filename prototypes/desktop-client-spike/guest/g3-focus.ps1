# PROTOTYPE - NOT FOR PRODUCTION
# Question: Do A (Compose Desktop) and B (Electron) render and accept Egyptian Arabic correctly on Windows 10 22H2 (G3, S6/S46, OQ22)?
# Date: 2026-10-17
# Brings the window whose title starts with -title to the foreground. Must run IN the cashier's interactive session
# (started through run-interactive.ps1 -wait), not over SSH. Writes the result to %TEMP%\g3-focus.txt.
param([string]$title)
$r = (New-Object -ComObject WScript.Shell).AppActivate($title)
"AppActivate('$title') = $r" | Out-File -Encoding utf8 (Join-Path $env:TEMP 'g3-focus.txt')
