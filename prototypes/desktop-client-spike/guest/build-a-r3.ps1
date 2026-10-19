# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
# Round 3 build of A on the VM: runs guest\build-a.ps1's toolchain twice, for 1.0.0 and 1.0.1 (same upgradeUuid),
# and copies both MSIs to C:\build\out\. Expects what build-a.ps1 expects in C:\build. Run as admin, unthrottled.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$b = 'C:\build'
Set-Location $b
function Unpack($zip, $to) { if (-not (Test-Path $to)) { New-Item -ItemType Directory $to | Out-Null; tar -xf $zip -C $to } }
Unpack (Get-ChildItem $b -Filter 'OpenJDK21U-jdk_x64_windows_*.zip').FullName "$b\jdk"
Unpack "$b\gradle-9.7.0-bin.zip" "$b\gradle"
Unpack "$b\wix314-binaries.zip" "$b\wix"
$env:JAVA_HOME = (Get-ChildItem "$b\jdk" -Directory | Select-Object -First 1).FullName
$env:Path = "$env:JAVA_HOME\bin;$b\wix;$((Get-ChildItem "$b\gradle" -Directory | Select-Object -First 1).FullName)\bin;$env:Path"
$env:GRADLE_USER_HOME = "$b\gradle-home"
New-Item -ItemType Directory -Force "$b\out" | Out-Null
Set-Location "$b\a-compose"
foreach ($v in '1.0.0', '1.0.1') {
  $t = [Diagnostics.Stopwatch]::StartNew()
  $ErrorActionPreference = 'Continue'
  & gradle.bat --no-daemon --console=plain "-PappVersion=$v" clean packageMsi *> "$b\build-a-$v.log"
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  "gradle packageMsi $v exit {0} in {1:N0} s" -f $code, $t.Elapsed.TotalSeconds
  $msi = Get-ChildItem "$b\a-compose\build" -Recurse -Filter *.msi -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($msi) { Copy-Item $msi.FullName "$b\out\KodeeboSpikeA-$v.msi"; "MSI ${v}: {0:N1} MB" -f ($msi.Length / 1MB) }
  else { Get-Content "$b\build-a-$v.log" -Tail 25 }
}
