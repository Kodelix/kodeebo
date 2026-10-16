# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Read-only: recent sshd log lines that mention a user (default: cashier).
param([string]$who = 'cashier', [int]$n = 15)
Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 300 -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -match $who } | Select-Object -First $n |
  ForEach-Object { $_.TimeCreated.ToString('HH:mm:ss') + ' ' + ($_.Message -replace '\s+', ' ') }
