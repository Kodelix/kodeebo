# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# G2 capture sink (admin): a Windows print queue "KSPIKE-SINK" with the in-box "Generic / Text Only" driver on a
# Local Port that is a FILE (C:\ksink\receipt.prn). A RAW job passes the spooler unchanged and lands in that file.
# Stands in for the AI-330 / XP-80C, whose runs stay PENDING (no hardware yet).
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$dir = 'C:\ksink'
$port = "$dir\receipt.prn"
if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
icacls $dir /grant 'Users:(OI)(CI)M' | Out-Null          # whoever the spooler writes as, it can write here
$drv = 'Generic / Text Only'
if (-not (Get-PrinterDriver -Name $drv -ErrorAction SilentlyContinue)) { Add-PrinterDriver -Name $drv }
if (-not (Get-PrinterPort -Name $port -ErrorAction SilentlyContinue)) { Add-PrinterPort -Name $port }
if (-not (Get-Printer -Name 'KSPIKE-SINK' -ErrorAction SilentlyContinue)) { Add-Printer -Name 'KSPIKE-SINK' -DriverName $drv -PortName $port }
Get-Printer -Name 'KSPIKE-SINK' | ForEach-Object { 'printer: {0} | driver: {1} | port: {2} | datatype: {3} | processor: {4}' -f $_.Name, $_.DriverName, $_.PortName, $_.Datatype, $_.PrintProcessor }
