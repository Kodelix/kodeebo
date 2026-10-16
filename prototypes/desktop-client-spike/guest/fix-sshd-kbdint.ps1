# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# One-off fix on the test VM: OpenSSH 7.7 keeps keyboard-interactive on despite "KbdInteractiveAuthentication no";
# add "ChallengeResponseAuthentication no" inside the kodeebo-spike block, then restart sshd.
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$cfg = 'C:\ProgramData\ssh\sshd_config'
$lines = @(Get-Content $cfg)
if ($lines -contains 'ChallengeResponseAuthentication no') { 'already present'; exit 0 }
$i = [Array]::IndexOf($lines, 'KbdInteractiveAuthentication no')
if ($i -lt 0) { throw 'kodeebo-spike block not found' }
$new = $lines[0..$i] + 'ChallengeResponseAuthentication no' + $lines[($i + 1)..($lines.Count - 1)]
Set-Content -Path $cfg -Value $new -Encoding ascii
Restart-Service sshd
'sshd restarted; status: ' + (Get-Service sshd).Status
