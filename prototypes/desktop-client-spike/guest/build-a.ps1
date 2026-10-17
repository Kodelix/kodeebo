# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
# G1 build of A on the VM (jpackage cannot cross-compile). Expects in C:\build: the JDK zip, Gradle zip, WiX zip
# and the project folder a-compose\. Writes the MSI path and timings. Run as admin, unthrottled, disposable layer.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$b = 'C:\build'
Set-Location $b
$sw = [Diagnostics.Stopwatch]::StartNew()
function Unpack($zip, $to) { if (-not (Test-Path $to)) { New-Item -ItemType Directory $to | Out-Null; tar -xf $zip -C $to } }
Unpack (Get-ChildItem $b -Filter 'OpenJDK21U-jdk_x64_windows_*.zip').FullName "$b\jdk"
Unpack "$b\gradle-9.7.0-bin.zip" "$b\gradle"
Unpack "$b\wix314-binaries.zip" "$b\wix"
"unpack: {0:N0} s" -f $sw.Elapsed.TotalSeconds
$env:JAVA_HOME = (Get-ChildItem "$b\jdk" -Directory | Select-Object -First 1).FullName
$env:Path = "$env:JAVA_HOME\bin;$b\wix;$((Get-ChildItem "$b\gradle" -Directory | Select-Object -First 1).FullName)\bin;$env:Path"
$env:GRADLE_USER_HOME = "$b\gradle-home"
$ErrorActionPreference = 'Continue'   # version banners go to stderr
& java -version 2>&1 | ForEach-Object { "$_" } | Select-Object -First 1
& candle.exe -? 2>&1 | ForEach-Object { "$_" } | Select-Object -First 1
$ErrorActionPreference = 'Stop'
Set-Location "$b\a-compose"
$t = [Diagnostics.Stopwatch]::StartNew()
$ErrorActionPreference = 'Continue'
& gradle.bat --no-daemon --console=plain packageMsi *> "$b\build-a.log"
$code = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
"gradle packageMsi exit {0} in {1:N0} s" -f $code, $t.Elapsed.TotalSeconds
Get-Content "$b\build-a.log" -Tail 25
$msi = Get-ChildItem "$b\a-compose\build" -Recurse -Filter *.msi -ErrorAction SilentlyContinue | Select-Object -First 1
if ($msi) { "MSI: {0} ({1:N1} MB)" -f $msi.FullName, ($msi.Length / 1MB) }
"Gradle cache size: {0:N0} MB" -f ((Get-ChildItem "$b\gradle-home" -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
