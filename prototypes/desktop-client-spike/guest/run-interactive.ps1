# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Run a program in the CURRENT user's interactive desktop session. Needed because an SSH session is not an
# interactive logon: msiexec returns 1601 there and GUI apps get no desktop; for a standard user the
# ScheduledTasks cmdlets fail too (WMI/CIM "Access denied"), so this uses schtasks.exe (/IT = interactive only,
# not elevated). A wrapper .cmd records the program's exit code.
# Usage: run-interactive.ps1 -exe <path> [-arguments "<args>"] [-wait] [-timeoutSec 600]
param([string]$exe, [string]$arguments = '', [switch]$wait, [int]$timeoutSec = 600)
$ErrorActionPreference = 'Stop'
$id = [Guid]::NewGuid().ToString('N').Substring(0, 8)
$name = "kspike-$id"
$wrap = Join-Path $env:TEMP "$name.cmd"
$done = Join-Path $env:TEMP "$name.exit"
Set-Content -Path $wrap -Encoding ascii -Value @(
  '@echo off',
  "start `"`" /wait `"$exe`" $arguments",
  "> `"$done`" echo %ERRORLEVEL%"   # redirect first: "echo 0> f" would redirect handle 0 and leave f empty
)
# -wait needs the wrapper (exit code); otherwise start the program directly, so no console window appears
$tr = if ($wait) { "`"$wrap`"" } else { ("`"$exe`" " + $arguments).Trim() }
# schtasks warns on stderr when /ST is already past (the task is started with /Run, so the time is irrelevant):
# do not let that warning stop the script; the exit code decides.
$ErrorActionPreference = 'Continue'
$null = & schtasks.exe /Create /TN $name /TR $tr /SC ONCE /ST 23:59 /IT /F 2>&1
if ($LASTEXITCODE -ne 0) { throw "schtasks /Create failed ($LASTEXITCODE)" }
$t0 = Get-Date
$null = & schtasks.exe /Run /TN $name 2>&1
"task {0} started at {1:HH:mm:ss.fff}" -f $name, $t0
if ($wait) {
  while (-not ((Test-Path $done) -and "$(Get-Content $done -ErrorAction SilentlyContinue)".Trim()) -and ((Get-Date) - $t0).TotalSeconds -lt $timeoutSec) { Start-Sleep -Milliseconds 250 }
  if (Test-Path $done) { "program exit code: {0} after {1:N1} s" -f "$(Get-Content $done)".Trim(), ((Get-Date) - $t0).TotalSeconds }
  else { "TIMEOUT after $timeoutSec s (task left: $name)"; exit 2 }
  $null = & schtasks.exe /Delete /TN $name /F 2>&1
  Remove-Item $wrap, $done -ErrorAction SilentlyContinue
} else {
  "task left registered: $name (delete with: schtasks /Delete /TN $name /F)"
}
