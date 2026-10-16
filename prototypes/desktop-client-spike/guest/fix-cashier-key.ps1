# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# Test VM only. OpenSSH 7.7 for Windows applied "Match User cashier -> AuthorizedKeysFile" on only some
# connections (about 40% of cashier logins failed, 2026-10-16). Move cashier's key to sshd's default per-user
# location and drop the Match block. Also turns the diagnostic LogLevel DEBUG3 off.
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'
$src = 'C:\ProgramData\ssh\cashier_authorized_keys'
$dir = 'C:\Users\cashier\.ssh'
$dst = Join-Path $dir 'authorized_keys'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
Copy-Item $src $dst -Force
icacls $dst /inheritance:r | Out-Null
icacls $dst /grant 'SYSTEM:(F)' 'BUILTIN\Administrators:(F)' 'cashier:(F)' | Out-Null
icacls $dst /setowner cashier | Out-Null
Remove-Item $src -Force

$cfg = 'C:\ProgramData\ssh\sshd_config'
$lines = @(Get-Content $cfg | Where-Object { $_ -ne 'LogLevel DEBUG3' })
$out = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $lines.Count; $i++) {
    # drop the trailing kodeebo-spike block (Match User cashier + AuthorizedKeysFile) and the blank line before it
    if ($lines[$i] -eq '# >>> kodeebo-spike (test VM only)' -and ($i + 1) -lt $lines.Count -and $lines[$i + 1] -eq 'Match User cashier') {
        while ($i -lt $lines.Count -and $lines[$i] -ne '# <<< kodeebo-spike') { $i++ }
        if ($out.Count -gt 0 -and $out[$out.Count - 1] -eq '') { $out.RemoveAt($out.Count - 1) }
        continue
    }
    $out.Add($lines[$i])
}
Set-Content -Path $cfg -Value $out.ToArray() -Encoding ascii
Restart-Service sshd
'cashier key: ' + $dst
icacls $dst
'Match User lines left: ' + @(Select-String -Path $cfg -Pattern 'Match User').Count
'LogLevel DEBUG3 left: ' + @(Select-String -Path $cfg -Pattern 'LogLevel DEBUG3').Count
'sshd ' + (Get-Service sshd).Status
