# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-17
# Founder question (1): how much of a cold start is reading from the (throttled) disk? Run as admin BEFORE the app
# starts. Process counters miss memory-mapped EXE/DLL paging (finding: B showed 1 MB read), so this also samples the
# DISK's cumulative read bytes (raw perf counter, all processes; the VM is otherwise idle) from the moment the app appears.
# starts. Waits for processes named $name, samples every process of that name every 250 ms (Win32_Process
# ReadTransferCount/WriteTransferCount = bytes the process asked to read/write, cache hits included, so an upper
# bound for disk reads) until all of them have exited, then prints a timeline and the totals.
param([string]$name, [int]$waitSec = 900)
$ErrorActionPreference = 'Continue'
$t0 = Get-Date
$seen = @{}            # pid -> last sample
$first = $null
$timeline = New-Object System.Collections.Generic.List[string]
function DiskRead { [int64](Get-CimInstance Win32_PerfRawData_PerfDisk_PhysicalDisk -Filter "Name = '_Total'").DiskReadBytesPersec }
$d0 = $null; $lastDisk = 0; $plateauMs = 0
while (((Get-Date) - $t0).TotalSeconds -lt $waitSec) {
  $ps = @(Get-CimInstance Win32_Process -Filter "Name = '$name.exe'" -ErrorAction SilentlyContinue)
  if ($ps.Count) {
    if (-not $first) { $first = ($ps | Sort-Object CreationDate | Select-Object -First 1).CreationDate; $d0 = DiskRead }
    $dk = (DiskRead) - $d0
    $ms = ((Get-Date) - $first).TotalMilliseconds
    if ($dk -gt $lastDisk + 512KB) { $plateauMs = $ms }   # last time the disk read more than 0.5 MB in one 250 ms step
    $lastDisk = $dk
    foreach ($p in $ps) { $seen[$p.ProcessId] = $p }
    $r = ($ps | Measure-Object ReadTransferCount -Sum).Sum
    $w = ($ps | Measure-Object WriteTransferCount -Sum).Sum
    $timeline.Add(('{0,7:N0} ms  procs={1}  proc_read={2:N1} MB  proc_write={3:N1} MB  disk_read={4:N1} MB' -f $ms, $ps.Count, ($r / 1MB), ($w / 1MB), ($dk / 1MB)))
  } elseif ($first) { break }
  Start-Sleep -Milliseconds 250
}
if (-not $first) { "no process '$name' seen in $waitSec s"; exit 2 }
# totals from the last sample of every pid seen (exited processes keep their final sample)
$rt = ($seen.Values | Measure-Object ReadTransferCount -Sum).Sum
$wt = ($seen.Values | Measure-Object WriteTransferCount -Sum).Sum
"processes seen: {0}; read total {1:N1} MB; write total {2:N1} MB; at 12 MiB/s the reads alone would take {3:N1} s" -f $seen.Count, ($rt / 1MB), ($wt / 1MB), ($rt / 12MB)
"disk read since the app appeared: {0:N1} MB, of which reading settled by ~{1:N0} ms; at 12 MiB/s that much sequential reading takes {2:N1} s" -f ($lastDisk / 1MB), $plateauMs, ($lastDisk / 12MB)
'timeline (every 4th sample):'
for ($i = 0; $i -lt $timeline.Count; $i += 4) { $timeline[$i] }
