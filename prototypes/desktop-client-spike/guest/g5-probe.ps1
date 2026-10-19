# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the M1 migration survive a power cut at every step, and does the app refuse a store it cannot trust (round 4, G5)?
# Date: 2026-10-19
# One line: every file in the runtime's store folder that round 4 cares about, with size and SHA-256 prefix (run as cashier).
param([string]$rt = 'a')
$d = Join-Path $env:LOCALAPPDATA "KodeeboSpike\$rt"
$out = @()
foreach ($n in 'store.db', 'store.db-journal', 'store.db.premigrate', 'store.db.premigrate.tmp', 'key.bin', 'store.id', 'quarantine.txt', 'hold.txt') {
  $p = Join-Path $d $n
  if (Test-Path -LiteralPath $p) { $i = Get-Item -LiteralPath $p; $out += "$n=$($i.Length)/$((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.Substring(0,16))" }
  else { $out += "$n=absent" }
}
$dm = @(Get-ChildItem $d -Directory -Filter 'damaged-*' -ErrorAction SilentlyContinue)
$pj = @(Get-ChildItem $d -Directory -Filter "prejournal-*" -ErrorAction SilentlyContinue)
foreach ($x in $pj) { foreach ($n in "store.db", "store.db-journal") { $q = Join-Path $x.FullName $n; if (Test-Path -LiteralPath $q) { $out += "$($x.Name)\$n=$((Get-Item -LiteralPath $q).Length)/$((Get-FileHash -LiteralPath $q -Algorithm SHA256).Hash.Substring(0,16))" } } }
$out += "damaged_dirs=$($dm.Count)"
$out -join ' '
