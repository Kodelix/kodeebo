# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
# Lists every Add/Remove Programs entry whose DisplayName matches -name, with its FULL registry path, in:
#   1. the machine-wide Uninstall keys (HKLM\SOFTWARE\[WOW6432Node\]Microsoft\Windows\CurrentVersion\Uninstall),
#   2. each loaded user hive's Uninstall key (HKEY_USERS\<sid>\Software\Microsoft\Windows\CurrentVersion\Uninstall),
#   3. Windows Installer's own registration (HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\<sid>\
#      Products\<packed code>\InstallProperties), where <sid> S-1-5-18 = per-machine and a user SID = per-user context.
# Run as admin. (Version 1 printed only "HKLM" and did not search area 3: G4-F1 needed the exact path.)
param([string]$name = 'KodeeboSpike')
$ErrorActionPreference = 'Continue'
$found = 0
function Report($area, $item) {
  $p = Get-ItemProperty $item.PSPath -ErrorAction SilentlyContinue
  if ($p.DisplayName -match $name) {
    $script:found++
    $path = $item.Name   # full key name, e.g. HKEY_LOCAL_MACHINE\SOFTWARE\...
    "uninstall-entry area=$area path=[$path] name=$($p.DisplayName) version=$($p.DisplayVersion) uninstall=[$($p.UninstallString)] location=[$($p.InstallLocation)]"
  }
}
foreach ($r in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
  if (Test-Path $r) { Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object { Report 'machine-Uninstall' $_ } }
}
Get-ChildItem Registry::HKEY_USERS | Where-Object { $_.PSChildName -match '^S-1-5-21-[\d-]+$' } | ForEach-Object {
  $r = "Registry::HKEY_USERS\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall"
  if (Test-Path $r) { Get-ChildItem $r -ErrorAction SilentlyContinue | ForEach-Object { Report 'user-Uninstall' $_ } }
}
$ud = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData'
if (Test-Path $ud) {
  Get-ChildItem $ud -ErrorAction SilentlyContinue | ForEach-Object {
    $sid = $_.PSChildName
    $prods = "$ud\$sid\Products"
    if (Test-Path $prods) {
      Get-ChildItem $prods -ErrorAction SilentlyContinue | ForEach-Object {
        $ip = "$($_.PSPath)\InstallProperties"
        if (Test-Path $ip) { Report "msi-UserData(sid=$sid)" (Get-Item $ip) }
      }
    }
  }
}
"uninstall-entries found=$found"
