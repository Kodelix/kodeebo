# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Read-only: every sshd event from "Connection from ... port <p>" up to the first line that mentions port <p> again, oldest first.
param([string]$port)
$ev = @(Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 2000 -ErrorAction SilentlyContinue)
[Array]::Reverse($ev)
$on = $false
foreach ($e in $ev) {
  $m = ($e.Message -replace '\s+', ' ')
  if (-not $on -and $m -match "Connection from .* port $port ") { $on = $true }
  if ($on) {
    $e.TimeCreated.ToString('HH:mm:ss.fff') + " pid=" + $e.ProcessId + ' ' + $m
    if ($m -match "(Failed|Accepted) publickey .* port $port ") { break }
  }
}
