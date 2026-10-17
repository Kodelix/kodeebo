# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# G2 sink check (admin): run "<app> --print-once" N times as cashier is done by the caller; this script is called
# AFTER EACH print. It waits until KSPIKE-SINK has no jobs, then compares C:\ksink\receipt.prn with the golden file
# byte for byte. On a mismatch it reports the first differing offset, the extra/missing byte count and the bytes.
param([string]$golden, [int]$timeoutSec = 60)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$sink = 'C:\ksink\receipt.prn'
$t0 = Get-Date
while (@(Get-PrintJob -PrinterName 'KSPIKE-SINK' -ErrorAction SilentlyContinue).Count -gt 0 -and ((Get-Date) - $t0).TotalSeconds -lt $timeoutSec) { Start-Sleep -Milliseconds 100 }
$queueMs = ((Get-Date) - $t0).TotalMilliseconds
if (-not (Test-Path $sink)) { 'sink: NO FILE'; exit 2 }
$g = [IO.File]::ReadAllBytes($golden)
$s = [IO.File]::ReadAllBytes($sink)
$hs = (Get-FileHash $sink -Algorithm SHA256).Hash.ToLower()
$hg = (Get-FileHash $golden -Algorithm SHA256).Hash.ToLower()
$first = -1
for ($i = 0; $i -lt [Math]::Min($g.Length, $s.Length); $i++) { if ($g[$i] -ne $s[$i]) { $first = $i; break } }
$equal = ($hs -eq $hg)
"sink bytes={0} golden bytes={1} sha256_equal={2} queue_drain_ms={3:N0}" -f $s.Length, $g.Length, $equal, $queueMs
if (-not $equal) {
  if ($first -ge 0) { "first difference at offset $first" }
  if ($s.Length -gt $g.Length) { "extra bytes at end ({0}): {1}" -f ($s.Length - $g.Length), (($s[$g.Length..($s.Length - 1)] | ForEach-Object { '{0:x2}' -f $_ }) -join ' ') }
  if ($s.Length -lt $g.Length) { "missing bytes at end: {0}" -f ($g.Length - $s.Length) }
  "sink head: " + (($s[0..([Math]::Min(15, $s.Length - 1))] | ForEach-Object { '{0:x2}' -f $_ }) -join ' ')
  "sink tail: " + (($s[([Math]::Max(0, $s.Length - 16))..($s.Length - 1)] | ForEach-Object { '{0:x2}' -f $_ }) -join ' ')
}
Remove-Item $sink -Force   # next job starts from an empty sink
