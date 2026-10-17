# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Read-only report after an install: where the exe landed, installed size, uninstall entries (per-user vs
# per-machine) and the scope lines of the MSI log if one exists.
param([string]$name, [string]$msiLog = '')
$ErrorActionPreference = 'Continue'
$roots = @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)})
$exe = Get-ChildItem $roots -Recurse -Filter "$name.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($exe) {
  'exe: ' + $exe.FullName
  'installed size: {0:N1} MB' -f ((Get-ChildItem $exe.Directory.FullName -Recurse -File | Measure-Object Length -Sum).Sum / 1MB)
} else { 'exe: NOT FOUND' }
$keys = @{ 'HKCU (per-user)' = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; 'HKLM (per-machine)' = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' }
foreach ($k in $keys.Keys) {
  Get-ItemProperty $keys[$k] -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" } |
    ForEach-Object { 'uninstall entry {0}: {1} {2} | InstallLocation={3}' -f $k, $_.DisplayName, $_.DisplayVersion, $_.InstallLocation }
}
if ($msiLog -and (Test-Path $msiLog)) {
  'MSI log:'
  Select-String -Path $msiLog -Pattern 'ALLUSERS', 'MSIINSTALLPERUSER', 'Privileged', 'AdminUser', 'Installation success or error status' |
    Select-Object -First 16 | ForEach-Object { '  ' + $_.Line.Trim() }
}
