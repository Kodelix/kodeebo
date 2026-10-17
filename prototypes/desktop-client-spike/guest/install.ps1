# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# G1: install a spike app as the STANDARD user "cashier" (run this over SSH as cashier, i.e. not elevated).
# A non-elevated, non-interactive session cannot answer a UAC prompt, so an installer that needs elevation fails here.
# Usage: install.ps1 -installer <path> -kind msi|exe -name <product name>
param([string]$installer, [ValidateSet('msi', 'exe')][string]$kind, [string]$name)
$ErrorActionPreference = 'Stop'
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$admin = (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"user: {0}; elevated admin token: {1}" -f $id.Name, $admin
$log = Join-Path $env:USERPROFILE "install-$name.log"
$sw = [Diagnostics.Stopwatch]::StartNew()
if ($kind -eq 'msi') { $p = Start-Process msiexec.exe -ArgumentList '/i', "`"$installer`"", '/qn', '/l*v', "`"$log`"" -Wait -PassThru }
else { $p = Start-Process $installer -ArgumentList '/S' -Wait -PassThru }
"installer exit code: {0}; time: {1:N1} s" -f $p.ExitCode, $sw.Elapsed.TotalSeconds
$keys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
foreach ($k in $keys) {
  Get-ItemProperty $k -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$name*" } |
    ForEach-Object { "uninstall entry: {0} | {1} | InstallLocation={2}" -f ($k -split '\\')[0], $_.DisplayName, $_.InstallLocation }
}
$exe = Get-ChildItem "$env:LOCALAPPDATA", "$env:ProgramFiles", "${env:ProgramFiles(x86)}" -Recurse -Filter "$name.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($exe) {
  "exe: " + $exe.FullName
  $dir = $exe.Directory.FullName
  "installed size: {0:N1} MB in {1}" -f ((Get-ChildItem $dir -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), $dir
} else { 'exe: NOT FOUND' }
if ($kind -eq 'msi' -and (Test-Path $log)) {
  'MSI log, scope-related lines:'
  Select-String -Path $log -Pattern 'Property\(S\): (ALLUSERS|MSIINSTALLPERUSER|Privileged|AdminUser|InstallScope)|Product: .* -- Installation|elevat' -ErrorAction SilentlyContinue |
    Select-Object -First 12 | ForEach-Object { '  ' + $_.Line.Trim() }
}
