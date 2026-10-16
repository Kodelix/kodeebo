# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# G0: check the HDD-class throttle from inside the guest with DiskSpd (signature checked before it runs).
# Usage (admin): powershell -NoProfile -ExecutionPolicy Bypass -File C:\g0\g0-diskspd.ps1 <label>
param([string]$label = 'run')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # progress bars fail over SSH (no console buffer)
$w = 'C:\g0'
if (-not (Test-Path "$w\diskspd\amd64\diskspd.exe")) { Expand-Archive "$w\DiskSpd.zip" "$w\diskspd" -Force }
$exe = "$w\diskspd\amd64\diskspd.exe"
$sig = Get-AuthenticodeSignature $exe
"diskspd.exe signature: {0}; signer: {1}" -f $sig.Status, $sig.SignerCertificate.Subject
if ($sig.Status -ne 'Valid') { throw 'diskspd.exe is not validly signed; not running it' }
"diskspd version: " + (Get-Item $exe).VersionInfo.ProductVersion
$f = "$w\t.dat"
# 1 GiB test file, 30 s per test, 5 s warm-up, software and hardware caching off (-Sh), latency stats (-L)
$tests = @(
  @{ name = 'random 4K 70/30 read/write, QD4'; args = @('-c1G', '-d30', '-W5', '-r', '-b4K', '-o4', '-t1', '-w30', '-Sh', '-L', $f) },
  @{ name = 'sequential 1M read, QD2';        args = @('-c1G', '-d30', '-W5', '-b1M', '-o2', '-t1', '-w0', '-Sh', '-L', $f) },
  @{ name = 'sequential 1M write, QD2';       args = @('-c1G', '-d30', '-W5', '-b1M', '-o2', '-t1', '-w100', '-Sh', '-L', $f) }
)
foreach ($t in $tests) {
  "=== [$label] $($t.name): diskspd $($t.args -join ' ')"
  $ErrorActionPreference = 'Continue'
  $out = & $exe @($t.args) 2>&1 | Out-String
  $ErrorActionPreference = 'Stop'
  # keep the per-direction 'total:' rows (bytes | I/Os | MiB/s | I/O per s | AvgLat | LatStdDev) and the latency table header
  $out -split "`r?`n" | Where-Object { $_ -match '^(Total IO|Read IO|Write IO)$' -or $_ -match '^total:' -or $_ -match '^\s+max \|' -or $_ -match '^\s+99th \|' } | ForEach-Object { $_ }
}
Remove-Item $f -Force
