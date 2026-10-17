# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Read-only (admin): processes matching a name pattern, with start time, CPU seconds, threads, window title, command line.
param([string]$pattern = 'Kodeebo|cmd|msiexec')
$ErrorActionPreference = 'Continue'
Get-CimInstance Win32_Process | Where-Object { $_.Name -match $pattern } | ForEach-Object {
  $p = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
  "{0} pid={1} parent={2} start={3:HH:mm:ss} cpu_s={4:N1} threads={5} session={6} title='{7}'" -f $_.Name, $_.ProcessId, $_.ParentProcessId, $_.CreationDate, $p.CPU, $p.Threads.Count, $_.SessionId, $p.MainWindowTitle
  "    cmd: " + $_.CommandLine
}
