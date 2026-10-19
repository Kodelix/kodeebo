# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
# Prints Windows' pending file rename/delete list (files an installer could not replace in use and scheduled for the
# next reboot), filtered to the spike apps, and the total count. Run as admin.
$v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations
if (-not $v) { "pending-file-renames: none"; exit 0 }
$k = @($v | Where-Object { $_ -match 'Kodeebo' })
"pending-file-renames: total-entries=$($v.Count) kodeebo-entries=$($k.Count)"
$k | Select-Object -First 20 | ForEach-Object { "pending: $_" }
