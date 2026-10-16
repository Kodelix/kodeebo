# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
#
# TEST VM ONLY ("kodeebo-win10"). Run ONCE, as Administrator, inside the VM:
#     powershell -ExecutionPolicy Bypass -File <CD drive>:\setup-ssh.ps1
#
# What it does (nothing else):
#   1. Installs the OpenSSH Server Windows capability (needs internet) and starts it at boot.
#   2. Allows ONE dedicated public key (spike_ed25519.pub, next to this script) for two users:
#      the administrator account (administrators_authorized_keys) and the standard user "cashier"
#      (C:\Users\cashier\.ssh\authorized_keys, sshd's default per-user location; "cashier" must have
#      signed in once so the profile exists). Password and keyboard-interactive logins are turned OFF.
#      (A "Match User cashier" + AuthorizedKeysFile rule was tried first: OpenSSH 7.7 for Windows applied it
#      on only about 60% of connections, 2026-10-16, evidence/g0-guest-channel.txt.)
#   3. Limits the SSH firewall rule to the libvirt NAT subnet 192.168.122.0/24.
#   4. Sets auto-logon for the test user "cashier" so GUI measurements have a desktop.
#      The password is read from a hidden prompt, checked against the local account, and written
#      only to the Winlogon registry values that auto-logon needs. It is never printed or sent.
#   5. Stops the screen from blanking, sleeping or showing the lock screen.
#
# It does NOT touch UAC, Windows Defender, Windows Update, or any other setting.
#
# AUTO-LOGON IS FOR THIS TEST VM ONLY. It must never be set on a venue PC or appear in any
# installer, install checklist or other venue install material.

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$pub  = (Get-Content -Raw (Join-Path $here 'spike_ed25519.pub')).Trim()
if ($pub -notmatch '^ssh-ed25519 [A-Za-z0-9+/=]+( [^\r\n]*)?$') { throw 'spike_ed25519.pub must be a single ssh-ed25519 line' }

# 1. OpenSSH Server
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
if ($cap.State -ne 'Installed') { Add-WindowsCapability -Online -Name $cap.Name | Out-Null }
Set-Service sshd -StartupType Automatic
Start-Service sshd          # first start creates sshd_config and the host keys
Stop-Service sshd

# 2. Keys and sshd_config
$dir = 'C:\ProgramData\ssh'
function Set-StrictAcl([string]$file) {
    icacls $file /inheritance:r | Out-Null
    icacls $file /grant 'SYSTEM:(F)' 'BUILTIN\Administrators:(F)' | Out-Null
}
$adminKeys   = Join-Path $dir 'administrators_authorized_keys'
$cashierDir  = 'C:\Users\cashier\.ssh'
$cashierKeys = Join-Path $cashierDir 'authorized_keys'
if (-not (Test-Path 'C:\Users\cashier')) { throw 'Sign in once as "cashier" first so its profile exists, then re-run.' }
if (-not (Test-Path $cashierDir)) { New-Item -ItemType Directory -Path $cashierDir | Out-Null }
Set-Content -Path $adminKeys   -Value $pub -Encoding ascii
Set-Content -Path $cashierKeys -Value $pub -Encoding ascii
Set-StrictAcl $adminKeys
Set-StrictAcl $cashierKeys
icacls $cashierKeys /grant 'cashier:(F)' | Out-Null
icacls $cashierKeys /setowner cashier | Out-Null

$cfg   = Join-Path $dir 'sshd_config'
$begin = '# >>> kodeebo-spike (test VM only)'
$end   = '# <<< kodeebo-spike'
$lines = @(Get-Content $cfg)
$out = New-Object System.Collections.Generic.List[string]
$skip = $false
foreach ($l in $lines) {                       # drop any earlier copy of our block: re-runnable
    if ($l -eq $begin) { $skip = $true; continue }
    if ($l -eq $end)   { $skip = $false; continue }
    if (-not $skip) { $out.Add($l) }
}
# OpenSSH 7.7 (the Windows 10 capability) ignores KbdInteractiveAuthentication; ChallengeResponseAuthentication
# is the switch that turns keyboard-interactive off there (found with sshd -T on the VM, 2026-10-16).
$top = @($begin, 'PasswordAuthentication no', 'KbdInteractiveAuthentication no', 'ChallengeResponseAuthentication no', 'PubkeyAuthentication yes', 'PermitEmptyPasswords no', $end)
Set-Content -Path $cfg -Value ($top + $out.ToArray()) -Encoding ascii

# 3. Firewall: only the libvirt NAT subnet
$rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
}
Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Enabled True -Profile Any -RemoteAddress '192.168.122.0/24'

# 4. Auto-logon for the test user "cashier" (password never echoed, stored or sent)
$sec  = Read-Host -AsSecureString 'Password of the TEST user "cashier" (hidden)'
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ctx = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('Machine')
if (-not $ctx.ValidateCredentials('cashier', $plain)) { Remove-Variable plain; throw 'That password is not valid for the local account "cashier". Nothing was written for auto-logon.' }
$k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $k AutoAdminLogon '1'
Set-ItemProperty $k DefaultUserName 'cashier'
Set-ItemProperty $k DefaultDomainName $env:COMPUTERNAME
Set-ItemProperty $k DefaultPassword $plain
Remove-Variable plain

# 5. Keep the screen on and unlocked
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
$pol = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'
if (-not (Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }
Set-ItemProperty $pol NoLockScreen 1 -Type DWord

Start-Service sshd
Write-Host ''
Write-Host 'Done. sshd host key fingerprint (the host side will compare it):'
ssh-keygen -lf (Join-Path $dir 'ssh_host_ed25519_key.pub')
Write-Host ''
Write-Host 'Next: restart the VM so auto-logon takes effect, then tell the assistant.'
