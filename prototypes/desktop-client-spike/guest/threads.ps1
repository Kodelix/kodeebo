# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Read-only (admin): Windows thread states and wait reasons of one process (tells "suspended" from "waiting").
param([int]$procId)
$p = Get-Process -Id $procId -ErrorAction Stop
"{0} pid={1} cpu_s={2:N1} threads={3} handles={4} responding={5}" -f $p.Name, $p.Id, $p.CPU, $p.Threads.Count, $p.HandleCount, $p.Responding
$p.Threads | Group-Object { "$($_.ThreadState)/$($_.WaitReason)" } | Sort-Object Count -Descending | ForEach-Object { "  {0,3} x {1}" -f $_.Count, $_.Name }
$p.Threads | Sort-Object TotalProcessorTime -Descending | Select-Object -First 5 | ForEach-Object { "  tid={0} cpu={1:N2}s state={2}/{3} start={4:HH:mm:ss}" -f $_.Id, $_.TotalProcessorTime.TotalSeconds, $_.ThreadState, $_.WaitReason, $_.StartTime }
