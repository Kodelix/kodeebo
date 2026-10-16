# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Diagnostic on the disposable layer only: set sshd LogLevel (on|off), restart sshd.
#Requires -RunAsAdministrator
param([ValidateSet('on', 'off')][string]$mode = 'on')
$cfg = 'C:\ProgramData\ssh\sshd_config'
$lines = @(Get-Content $cfg | Where-Object { $_ -ne 'LogLevel DEBUG3' })
if ($mode -eq 'on') { $lines = @('LogLevel DEBUG3') + $lines }
Set-Content -Path $cfg -Value $lines -Encoding ascii
Restart-Service sshd
"sshd LogLevel DEBUG3: $mode; sshd " + (Get-Service sshd).Status
