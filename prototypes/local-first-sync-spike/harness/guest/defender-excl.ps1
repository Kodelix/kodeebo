# PROTOTYPE - NOT FOR PRODUCTION
# Runs ON THE VM as administrator (phase 4, P4-F4). Adds or removes Defender exclusions for the encrypted store and
# its journal ONLY, by exact path (never the folder, never an executable):
#   defender-excl.ps1 -Action add|remove -Mode paths|contextual -Dir <store folder> -Proc <app executable>
# contextual: the exclusion applies only when the app's own process opens the file (Defender platform 4.18.2205.7+).
param([string]$Action, [string]$Mode, [string]$Dir, [string]$Proc)
$targets = @("$Dir\client.db", "$Dir\client.db-journal")
if ($Mode -eq 'contextual') { $entries = $targets | ForEach-Object { "$_\:{PathType:file,Process:`"$Proc`"}" } }
else { $entries = $targets }
foreach ($e in $entries) {
  if ($Action -eq 'add') { Add-MpPreference -ExclusionPath $e } else { Remove-MpPreference -ExclusionPath $e }
}
"platform=" + (Get-MpComputerStatus).AMProductVersion
"exclusions=" + ((Get-MpPreference).ExclusionPath -join ' | ')
