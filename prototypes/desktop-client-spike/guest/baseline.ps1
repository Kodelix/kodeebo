# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Read-only: prints the VM's baseline state (OS build, updates, WebView2, Defender, UAC, sshd effective auth settings).
$ErrorActionPreference = 'Continue'
$v = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
'OS: {0} {1} build {2}.{3} ({4})' -f $v.ProductName, $v.DisplayVersion, $v.CurrentBuild, $v.UBR, $v.EditionID
'Hotfixes: ' + ((Get-HotFix | Sort-Object InstalledOn | ForEach-Object { '{0} {1:yyyy-MM-dd}' -f $_.HotFixID, $_.InstalledOn }) -join '; ')
$wv = Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' -ErrorAction SilentlyContinue
'WebView2 runtime (machine): ' + $(if ($wv) { $wv.pv } else { 'not installed' })
$e = Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge' -ErrorAction SilentlyContinue
'Edge: ' + $(if ($e) { $e.DisplayVersion } else { 'not found' })
$d = Get-MpComputerStatus
'Defender real-time protection: {0}; AV signatures {1}' -f $d.RealTimeProtectionEnabled, $d.AntivirusSignatureVersion
'wuauserv: {0}; reboot required by Windows Update: {1}' -f (Get-Service wuauserv).Status, (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
$c = Get-CimInstance Win32_ComputerSystem
'RAM: {0:N0} MB; logical CPUs: {1}' -f ($c.TotalPhysicalMemory / 1MB), $c.NumberOfLogicalProcessors
$dk = Get-PSDrive C
'C: used {0:N1} GB, free {1:N1} GB' -f ($dk.Used / 1GB), ($dk.Free / 1GB)
'TPM present: ' + (Get-Tpm).TpmPresent
$s = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
'UAC EnableLUA={0}; ConsentPromptBehaviorAdmin={1}; ConsentPromptBehaviorUser={2}' -f $s.EnableLUA, $s.ConsentPromptBehaviorAdmin, $s.ConsentPromptBehaviorUser
'sshd version: ' + (Get-Item 'C:\Windows\System32\OpenSSH\sshd.exe').VersionInfo.ProductVersion
'sshd effective auth settings:'
& 'C:\Windows\System32\OpenSSH\sshd.exe' -T 2>&1 | Select-String -Pattern '^(passwordauthentication|kbdinteractiveauthentication|challengeresponseauthentication|pubkeyauthentication|permitemptypasswords|authenticationmethods) ' | ForEach-Object { '  ' + $_.Line }
