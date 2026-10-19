# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
# Timeline probe for G4.4: one line per call with msiexec process count, whether C:\Users\cashier\cut.log exists and
# its size, and the last MSI action line in it. Run as admin, repeatedly, while an upgrade runs.
$n = @(Get-Process msiexec -ErrorAction SilentlyContinue).Count
$f = 'C:\Users\cashier\cut.log'
if (Test-Path $f) {
  $len = (Get-Item $f).Length
  $last = (Select-String -Path $f -Pattern '^Action (start|ended) [0-9:]+: [A-Za-z]+\.' -Encoding Unicode -ErrorAction SilentlyContinue | Select-Object -Last 1).Line
  "msiexec=$n log=$len last=[$last]"
} else { "msiexec=$n log=absent" }
