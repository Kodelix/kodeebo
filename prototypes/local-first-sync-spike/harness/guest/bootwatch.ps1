# PROTOTYPE - NOT FOR PRODUCTION
# Runs ON THE VM as administrator (phase 4 set 4, founder 2026-10-21): names what Windows is doing in the first
# minutes after boot, while the counter sells (S309's slow sales came in the first 28 minutes). Every <Every> seconds
# for <Minutes> minutes, one JSON line:
#   top 6 processes by disk I/O (IO Data Bytes/sec) and by CPU, with their service names when they are svchost;
#   the scheduled tasks running now; the state of the services usually busy after a boot (Windows Update, BITS,
#   Delivery Optimization, Search indexer, SysMain, Defender) and whether a Defender scan is running.
#   bootwatch.ps1 -Out <file.jsonl> [-Minutes 30] [-Every 10]
param([string]$Out, [int]$Minutes = 30, [int]$Every = 10)
$svcs = 'wuauserv', 'BITS', 'DoSvc', 'WSearch', 'SysMain', 'WinDefend', 'TrustedInstaller', 'UsoSvc'
$end = (Get-Date).AddMinutes($Minutes)
while ((Get-Date) -lt $end) {
  $t = Get-Date
  $c = (Get-Counter '\Process(*)\IO Data Bytes/sec', '\Process(*)\% Processor Time', '\Process(*)\ID Process' -ErrorAction SilentlyContinue).CounterSamples |
       Where-Object { $_.InstanceName -notin '_total', 'idle' }
  $pidOf = @{}; $c | Where-Object { $_.Path -like '*id process*' } | ForEach-Object { $pidOf[$_.Path.Split('(')[1].Split(')')[0]] = [int]$_.CookedValue }
  $io = $c | Where-Object { $_.Path -like '*io data bytes*' } | Sort-Object CookedValue -Descending | Select-Object -First 6 |
        ForEach-Object { @{ p = $_.InstanceName; pid = $pidOf[$_.Path.Split('(')[1].Split(')')[0]]; v = [math]::Round($_.CookedValue) } }
  $cpu = $c | Where-Object { $_.Path -like '*processor time*' } | Sort-Object CookedValue -Descending | Select-Object -First 6 |
         ForEach-Object { @{ p = $_.InstanceName; pid = $pidOf[$_.Path.Split('(')[1].Split(')')[0]]; v = [math]::Round($_.CookedValue, 1) } }
  $tasks = Get-ScheduledTask | Where-Object { $_.State -eq 'Running' } | ForEach-Object { $_.TaskPath + $_.TaskName }
  $state = @{}
  foreach ($s in $svcs) { $x = Get-Service -Name $s -ErrorAction SilentlyContinue; if ($x) { $state[$s] = "$($x.Status)" } }
  $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
  if (-not $svchost -or $t.Second -lt $Every) {  # the pid -> services map, refreshed about once a minute
    $svchost = Get-CimInstance Win32_Service -Filter "State='Running'" | Group-Object ProcessId |
               ForEach-Object { @{ pid = $_.Name; svc = ($_.Group.Name -join ',') } }
  }
  $line = @{ t = $t.ToString('o'); io = $io; cpu = $cpu; tasks = $tasks; services = $state;
             defender_scan = @{ full = $mp.FullScanRunning; quick = $mp.QuickScanRunning };
             svchost_groups = $svchost } | ConvertTo-Json -Compress -Depth 4
  Add-Content -Path $Out -Value $line
  $wait = $Every - ((Get-Date) - $t).TotalSeconds
  if ($wait -gt 0) { Start-Sleep -Seconds $wait }
}
