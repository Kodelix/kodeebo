# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the M1 migration survive a power cut at every step, and does the app refuse a store it cannot trust (round 4, G5)?
# Date: 2026-10-19
# Round 4 build of A on the VM: guest\build-a.ps1's toolchain twice, 1.0.1 (schema 1) and 1.0.2 (schema 2), same upgradeUuid;
# and copies both MSIs to C:\build\out\. Expects what build-a.ps1 expects in C:\build. Run as admin, unthrottled.
param([string]$builds = '1.0.1:1,1.0.2:2')   # version:schemaMax pairs (1.0.3:2 = the TS-03c journal-leg build)
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
foreach ($p in $builds.Split(',')) {
  $v, $sm = $p.Split(':')
  $t = [Diagnostics.Stopwatch]::StartNew()
  $ErrorActionPreference = 'Continue'
  & gradle.bat --no-daemon --console=plain "-PappVersion=$v" "-PschemaMax=$sm" clean packageMsi *> "$b\build-a-$v.log"
  $code = $LASTEXITCODE
  $ErrorActionPreference = 'Stop'
  "gradle packageMsi $v exit {0} in {1:N0} s" -f $code, $t.Elapsed.TotalSeconds
  $msi = Get-ChildItem "$b\a-compose\build" -Recurse -Filter *.msi -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($msi) { Copy-Item $msi.FullName "$b\out\KodeeboSpikeA-$v.msi"; "MSI ${v}: {0:N1} MB" -f ($msi.Length / 1MB) }
  else { Get-Content "$b\build-a-$v.log" -Tail 25 }
}
