# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Memory of a process TREE (the app and every descendant), run as admin (WMI is denied to cashier over SSH).
# Prints working set and private bytes, summed and per process.
param([int]$rootPid)
$ErrorActionPreference = 'Stop'
$all = @(Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId, Name, WorkingSetSize, PrivatePageCount)
$tree = New-Object System.Collections.Generic.List[object]
$queue = New-Object System.Collections.Generic.Queue[int]
$queue.Enqueue($rootPid)
while ($queue.Count) {
  $id = $queue.Dequeue()
  $p = $all | Where-Object ProcessId -eq $id
  if ($p) { $tree.Add($p) }
  $all | Where-Object ParentProcessId -eq $id | ForEach-Object { $queue.Enqueue($_.ProcessId) }
}
if (-not $tree.Count) { "pid $rootPid not found"; exit 2 }
"tree: {0} processes; working set {1:N1} MB; private bytes {2:N1} MB" -f $tree.Count, (($tree | Measure-Object WorkingSetSize -Sum).Sum / 1MB), (($tree | Measure-Object PrivatePageCount -Sum).Sum / 1MB)
$tree | ForEach-Object { "  {0} pid={1} ws={2:N1} MB private={3:N1} MB" -f $_.Name, $_.ProcessId, ($_.WorkingSetSize / 1MB), ($_.PrivatePageCount / 1MB) }
$os = Get-CimInstance Win32_OperatingSystem
"system: free physical {0:N0} MB of {1:N0} MB" -f ($os.FreePhysicalMemory / 1KB), ($os.TotalVisibleMemorySize / 1KB)
