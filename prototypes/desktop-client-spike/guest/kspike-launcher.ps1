# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does a launcher outside the program folder that re-runs the last good installer make the app start after every
# power cut during an update, with nobody reinstalling (round 3, G4.5)?
# Date: 2026-10-18
#
# Runs as the cashier, from %LOCALAPPDATA%\KodeeboSpikeLauncher\<rt>\ (outside the program folder and the store folder).
#   -rt a|b -stage <installer> -version <v> -files <n> -bytes <n>   copy the installer to installers\<v>\ with its manifest
#   -rt a|b -init <v>                                                journal: state=ok version=<v> (installed by hand)
#   -rt a|b -update <v>                                              journal updating, close app, run installer, verify, ok
#   -rt a|b                                                          launch: repair if needed, then start the app
# Every action is logged with a timestamp in launcher.log. The journal is written to a temp file with write-through,
# then moved over the old one, so a power cut leaves either the old or the new journal.
param([string]$rt = 'a', [string]$stage = '', [string]$version = '', [long]$files = 0, [long]$bytes = 0,
      [string]$init = '', [string]$update = '')
$ErrorActionPreference = 'Continue'
$home_ = Join-Path $env:LOCALAPPDATA "KodeeboSpikeLauncher\$rt"
$null = New-Item -ItemType Directory -Force -Path $home_
$logf = Join-Path $home_ 'launcher.log'
$jf = Join-Path $home_ 'journal.txt'
if ($rt -eq 'a') { $prog = "$env:LOCALAPPDATA\KodeeboSpikeA"; $exe = "$prog\KodeeboSpikeA.exe"; $kind = 'msi' }
else { $prog = "$env:LOCALAPPDATA\Programs\kodeebo-spike-b"; $exe = "$prog\KodeeboSpikeB.exe"; $kind = 'exe' }

function Log($m) {
  $line = '{0:yyyy-MM-dd HH:mm:ss.fff} {1}' -f (Get-Date), $m
  $fs = [IO.FileStream]::new($logf, [IO.FileMode]::Append, [IO.FileAccess]::Write, [IO.FileShare]::Read, 4096, [IO.FileOptions]::WriteThrough)
  $b = [Text.Encoding]::UTF8.GetBytes($line + "`r`n"); $fs.Write($b, 0, $b.Length); $fs.Close()
}
function WriteDurable($path, $text) {
  $tmp = "$path.tmp"
  $fs = [IO.FileStream]::new($tmp, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None, 4096, [IO.FileOptions]::WriteThrough)
  $b = [Text.Encoding]::UTF8.GetBytes($text); $fs.Write($b, 0, $b.Length); $fs.Flush($true); $fs.Close()
  Move-Item -LiteralPath $tmp -Destination $path -Force
}
function ReadKv($path) {
  $h = @{}
  if (Test-Path $path) { foreach ($l in Get-Content $path) { if ($l -match '^([a-z_]+)=(.*)$') { $h[$Matches[1]] = $Matches[2] } } }
  return $h
}
function Journal($h) { WriteDurable $jf (($h.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join "`r`n") }
function InstallerOf($v) { Get-ChildItem (Join-Path $home_ "installers\$v") -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.msi', '.exe' } | Select-Object -First 1 }
function FolderState() {
  if (-not (Test-Path $prog)) { return @{ files = 0; bytes = 0 } }
  $f = Get-ChildItem $prog -Recurse -File -ErrorAction SilentlyContinue
  return @{ files = [long]$f.Count; bytes = [long](($f | Measure-Object Length -Sum).Sum) }
}
# Healthy = executable present and the program folder matches version $v's manifest (file count and bytes)
function Healthy($v) {
  $m = ReadKv (Join-Path $home_ "installers\$v\manifest.txt"); $s = FolderState
  $ok = (Test-Path $exe) -and $m.files -and ([long]$m.files -eq $s.files) -and ([long]$m.bytes -eq $s.bytes)
  Log "check v=$v exe=$(Test-Path $exe) folder files=$($s.files) bytes=$($s.bytes) manifest files=$($m.files) bytes=$($m.bytes) -> $(if ($ok) {'healthy'} else {'NOT healthy'})"
  return $ok
}
function RunInstaller($v) {
  $i = InstallerOf $v
  if (-not $i) { Log "no staged installer for $v"; return 99 }
  $t0 = Get-Date
  # Windows Installer may still be busy after a boot (1618 = another installation in progress): retry for up to 10 min
  for ($try = 1; $try -le 20; $try++) {
    # /l*v! flushes every line (as round 3's cut path, so the G4.4 offsets for A still cover the same phases)
    $ml = Join-Path $home_ ('msi-{0}-{1:yyyyMMdd-HHmmss}.log' -f $v, (Get-Date))
    if ($kind -eq 'msi') { $p = Start-Process msiexec.exe -ArgumentList "/i `"$($i.FullName)`" /qn /norestart /l*v! `"$ml`"" -Wait -PassThru }
    else { $p = Start-Process $i.FullName -ArgumentList '/S' -Wait -PassThru }
    $code = $p.ExitCode
    Log "installer $v try $try exit=$code after $([int]((Get-Date) - $t0).TotalSeconds) s"
    if ($code -ne 1618) { break }
    Start-Sleep -Seconds 30
  }
  # NSIS: the installer may hand off to a copy of itself; wait until the folder settles (max 600 s)
  if ($kind -eq 'exe') {
    for ($k = 0; $k -lt 120; $k++) {
      if (-not (Get-Process | Where-Object { $_.Path -and $_.Path -like "$home_\installers\*" -or $_.Name -match '^(Un_|Au_)' })) { break }
      Start-Sleep -Seconds 5
    }
  }
  return $code
}
function StopApp() {
  $n = [IO.Path]::GetFileNameWithoutExtension($exe)
  $ps = Get-Process -Name $n -ErrorAction SilentlyContinue
  if ($ps) { $ps | Stop-Process -Force; Log "closed running app ($($ps.Count) processes)"; Start-Sleep -Seconds 2 }
}
# Make version $v healthy: run its installer, check; returns $true if healthy afterwards
function Ensure($v) {
  $null = RunInstaller $v
  if (Healthy $v) { return $true }
  Log "installer for $v did not give a healthy folder; second try"
  $null = RunInstaller $v
  return (Healthy $v)
}

if ($stage) {
  $d = Join-Path $home_ "installers\$version"; $null = New-Item -ItemType Directory -Force -Path $d
  Copy-Item -LiteralPath $stage -Destination $d -Force
  WriteDurable (Join-Path $d 'manifest.txt') "version=$version`r`nfiles=$files`r`nbytes=$bytes"
  Log "staged $version from $stage (manifest files=$files bytes=$bytes)"; exit 0
}
if ($init) { Journal @{ state = 'ok'; version = $init; last_good = $init }; Log "init: state=ok version=$init"; exit 0 }

$j = ReadKv $jf
if ($update) {
  Journal @{ state = 'updating'; target = $update; last_good = $j.last_good; version = $j.version }
  Log "update to ${update}: journal state=updating (last good $($j.last_good))"
  StopApp
  Log "update to ${update}: installer starting"
  $ok = Ensure $update
  if ($ok) { Journal @{ state = 'ok'; version = $update; last_good = $update }; Log "update to ${update}: done, state=ok" }
  else { Log "update to ${update}: FAILED; journal left updating, the next launch repairs" }
  exit 0
}

# Launch
Log "launch: journal $(($j.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ' ')"
if ($j.state -eq 'updating') {
  # before-repair record (founder, G4.5 supplementary set): what the cut left in the program folder
  $s = FolderState
  Log "launch: before repair: exe=$(Test-Path $exe) folder files=$($s.files) bytes=$($s.bytes) (target $($j.target), last good $($j.last_good))"
  Log "launch: interrupted update to $($j.target) found; re-running its installer"
  if (Ensure $j.target) { Journal @{ state = 'ok'; version = $j.target; last_good = $j.target }; Log "launch: repaired to $($j.target)" }
  elseif ($j.last_good -and (Ensure $j.last_good)) { Journal @{ state = 'ok'; version = $j.last_good; last_good = $j.last_good }; Log "launch: fell back to last good $($j.last_good)" }
  else { Log "launch: REPAIR FAILED" }
} elseif (-not (Healthy $j.version)) {
  Log "launch: program folder not healthy; re-running the last good installer $($j.last_good)"
  if (Ensure $j.last_good) { Journal @{ state = 'ok'; version = $j.last_good; last_good = $j.last_good }; Log "launch: repaired to $($j.last_good)" }
  else { Log "launch: REPAIR FAILED" }
}
if (Test-Path $exe) { Start-Process $exe; Log "launch: app started" } else { Log "launch: NO EXECUTABLE, app not started" }
