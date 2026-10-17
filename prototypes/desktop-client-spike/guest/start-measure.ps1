# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# G1 start measurement, run as cashier over SSH. Starts the app on cashier's desktop (schtasks /IT via
# run-interactive.ps1), waits for the new ready.txt line the app writes after its first painted frame (SPEC.md).
# Prints: label, OS process start -> first frame (ms), launch request -> first frame (ms), pid.
# Leaves the app running unless -kill.
param([string]$exe, [string]$rt, [string]$label = 'run', [int]$timeoutSec = 180, [switch]$kill)
$ErrorActionPreference = 'Stop'
$ready = Join-Path $env:LOCALAPPDATA "KodeeboSpike\$rt\ready.txt"
$before = if (Test-Path $ready) { @(Get-Content $ready).Count } else { 0 }
$launchMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$null = & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $env:USERPROFILE 'run-interactive.ps1') -exe $exe
$line = $null
$t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt $timeoutSec) {
  if (Test-Path $ready) {
    $all = @(Get-Content $ready)
    if ($all.Count -gt $before) { $line = $all[$before]; break }
  }
  Start-Sleep -Milliseconds 100
}
# the wrapper task stays "running" while the app runs; remove the task definition (does not stop the app)
& schtasks.exe /Query /FO CSV /NH 2>$null | Select-String 'kspike-' | ForEach-Object { ($_ -split ',')[0].Trim('"\') } |
  ForEach-Object { $null = & schtasks.exe /Delete /TN $_ /F 2>&1 }
if (-not $line) { "{0} TIMEOUT: no ready line after {1} s" -f $label, $timeoutSec; exit 2 }
$kv = @{}; foreach ($p in $line -split ' ') { $a = $p -split '=', 2; $kv[$a[0]] = $a[1] }
$procToFrame = [int64]$kv['first_frame_ms'] - [int64]$kv['proc_start_ms']
$launchToFrame = [int64]$kv['first_frame_ms'] - $launchMs
"{0} proc_to_first_frame_ms={1} launch_to_first_frame_ms={2} pid={3}" -f $label, $procToFrame, $launchToFrame, $kv['pid']
if ($kill) { $null = & taskkill.exe /PID $kv['pid'] /T /F 2>&1 }
