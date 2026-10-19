# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
# What is on disk for the spike apps of the CURRENT user (run as cashier): program folders, the store folders and
# Electron's userData folder, with file counts, sizes, and the store files' SHA-256 prefixes.
$ErrorActionPreference = 'Continue'
$dirs = @(
  "$env:LOCALAPPDATA\KodeeboSpikeA",                 # A's per-user MSI install folder (round 1)
  "$env:LOCALAPPDATA\Programs\kodeebo-spike-b",      # B's per-user NSIS install folder (round 1)
  "$env:LOCALAPPDATA\KodeeboSpike\a",                # A's store and run files
  "$env:LOCALAPPDATA\KodeeboSpike\b",                # B's store and run files
  "$env:APPDATA\KodeeboSpikeB"                       # Electron userData (what deleteAppDataOnUninstall targets)
)
foreach ($d in $dirs) {
  if (Test-Path $d) {
    $f = Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue
    "dir present: $d files=$($f.Count) bytes=$(($f | Measure-Object Length -Sum).Sum)"
  } else { "dir absent: $d" }
}
foreach ($rt in 'a', 'b') {
  foreach ($n in 'store.db', 'key.bin', 'store.db-journal') {
    $p = "$env:LOCALAPPDATA\KodeeboSpike\$rt\$n"
    if (Test-Path $p) { "store file: $rt\$n bytes=$((Get-Item $p).Length) sha256=$((Get-FileHash $p -Algorithm SHA256).Hash.Substring(0,16))" }
  }
}
