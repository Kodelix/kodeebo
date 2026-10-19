#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
#
# Round 3 G4 driver (README "Round 3"). Steps (every step appends to .cache/g4-<date>.txt):
#   build-a                     disposable layer: revert clean-ssh2, build A 1.0.0 and 1.0.1 (guest/build-a-r3.ps1), fetch both
#                               MSIs to .cache/r3-a/, shut off
#   prep                        revert clean-ssh2, boot, HDD throttle, copy helpers, create the KSPIKE-SINK print queue
#   install <rt> <file> <msi|exe>   copy and install as cashier, wait; logs exit code and duration; screenshot at +10 s
#                               (UAC check); for MSI fetches the verbose log to .cache/ and prints its context properties
#   run <rt> <args...>          run the installed app with args as cashier and wait (e.g. --close-bench 20, --check, --version)
#   state <rt> <label>          --version + --check (last lines), then uninstall entries (g4-hive.ps1) and files (g4-files.ps1)
#   gui <rt> <label>            start the GUI (no wait), sleep, screenshot to evidence/g4/<rt>-<label>.png
#   selfupdate <rt> <installer in VM>  the app's own --self-update (starts the installer detached and exits)
#   uninstall <rt> <label>      uninstall silently as cashier (A: msiexec /x {code} /qn from the uninstall entry; B: NSIS /S)
#   shot <name>                 screenshot to evidence/g4/<name>.png
#   snap-save <name>            shut off and take an offline snapshot (temporary, deleted at the end of round 3)
#   snap-boot <name> [nothrottle]   revert to snapshot <name>, start, wait for cashier's logon, throttle (unless nothrottle)
#   cut <rt> <installer in VM> <offset s> <label>   start the upgrade (no wait), hard power-off (virsh destroy) after
#                               <offset> s, boot UNTHROTTLED, then --version, --check, files, then re-run the installer
#                               (wait) and --version, --check again; one summary line "CUT ..." per cut
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
VM="$D/tools/vm.sh"
V="virsh -c qemu:///system"
DOM=kodeebo-win10
out="$D/.cache/g4-$(date +%Y%m%d).txt"
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$out"; }
cash() { "$VM" ssh cashier "$@" 2>&1 | tr -d '\r'; }
adm() { "$VM" ssh admin "$@" 2>&1 | tr -d '\r'; }
waitssh() { for i in $(seq 1 180); do "$VM" ssh "$1" 'echo up' 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
waitlogon() { for i in $(seq 1 120); do { q=$("$VM" ssh admin 'query user' 2>/dev/null); grep -q -i 'cashier.*Active' <<<"$q"; } && return 0; sleep 5; done; return 1; }
throttle() { $V blkdeviotune $DOM sda --live --total-iops-sec 100 --total-bytes-sec 83886080; }
shutoff() {
  [ "$($V domstate $DOM)" = "shut off" ] && return 0
  "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1
  for i in $(seq 1 36); do [ "$($V domstate $DOM)" = "shut off" ] && return 0; sleep 5; done
  $V destroy $DOM >/dev/null; log "shutoff: guest did not stop in 180 s; destroyed"
}
RI='C:\Users\cashier\run-interactive.ps1'
interactive() { cash powershell -NoProfile -ExecutionPolicy Bypass -File "$RI" -exe "$1" -arguments "\"$2\"" ${3:-}; }
exe_of() { case "$1" in a) echo 'C:\Users\cashier\AppData\Local\KodeeboSpikeA\KodeeboSpikeA.exe' ;; b) echo 'C:\Users\cashier\AppData\Local\Programs\kodeebo-spike-b\KodeeboSpikeB.exe' ;; esac; }
data_of() { echo "C:\\Users\\cashier\\AppData\\Local\\KodeeboSpike\\$1"; }
last() { cash "powershell -NoProfile -Command \"if (Test-Path $(data_of "$1")\\$2) { Get-Content $(data_of "$1")\\$2 -Tail 1 } else { 'no $2' }\"" | tail -1; }
lines() { cash "powershell -NoProfile -Command \"if (Test-Path $(data_of "$1")\\$2) { (Get-Content $(data_of "$1")\\$2).Count } else { 0 }\"" | tail -1; }
# appcheck <rt>: "APP MISSING" if the executable is absent (launching it would block on a Windows error dialog: s2k5);
# otherwise run --version and --check and print their lines ONLY if they are new (old lines were misread in s2k5)
appcheck() {
  local rt=$1 ex; ex=$(exe_of "$rt")
  if ! cash "powershell -NoProfile -Command \"Test-Path '$ex'\"" | grep -q True; then echo "[APP MISSING: $ex] [no check run]"; return; fi
  local nv nc; nv=$(lines "$rt" version.txt); nc=$(lines "$rt" check.txt)
  interactive "$ex" --version -wait >/dev/null; interactive "$ex" --check -wait >/dev/null
  local v c; [ "$(lines "$rt" version.txt)" -gt "${nv:-0}" ] 2>/dev/null && v=$(last "$rt" version.txt) || v="NO NEW version LINE (app did not run)"
  [ "$(lines "$rt" check.txt)" -gt "${nc:-0}" ] 2>/dev/null && c=$(last "$rt" check.txt) || c="NO NEW check LINE (app did not run)"
  echo "[$v] [$c]"
}
upgrade_cmd() {  # <installer in VM> -> program and arguments for a silent install
  # MSI: /l*v! flushes every line, so after a power cut the log shows the last action reached (G4.4 phase)
  case "$1" in *.msi) echo "msiexec.exe|/i $1 /qn /l*v! C:\\Users\\cashier\\cut.log" ;; *) echo "$1|/S" ;; esac
}

step=${1:?step}; shift
case "$step" in
build-a)
  shutoff; $V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null && waitssh admin || { log "build-a: VM did not come up"; exit 1; }
  log "build-a: reverted clean-ssh2, booted unthrottled"
  tar -C "$D/apps" --exclude=build --exclude=.gradle --exclude=.kotlin -cf "$D/.cache/r3-a-compose.tar" a-compose
  adm 'powershell -NoProfile -Command "New-Item -ItemType Directory -Force C:\build | Out-Null"' >/dev/null
  for f in "$D/.cache/dl/temurin-jdk21/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip" \
           "$D/.cache/dl/gradle-9.7.0/gradle-9.7.0-bin.zip" "$D/.cache/dl/wix-3.14/wix314-binaries.zip" \
           "$D/.cache/r3-a-compose.tar" "$D/guest/build-a-r3.ps1"; do "$VM" put admin "$f" "C:/build/$(basename "$f")"; done
  adm 'cd C:\build && tar -xf r3-a-compose.tar' >/dev/null
  log "build-a: building 1.0.0 and 1.0.1"
  adm 'powershell -NoProfile -ExecutionPolicy Bypass -File C:\build\build-a-r3.ps1' | tee -a "$out"
  mkdir -p "$D/.cache/r3-a"
  for v in 1.0.0 1.0.1; do
    "$VM" get admin "C:/build/out/KodeeboSpikeA-$v.msi" "$D/.cache/r3-a/KodeeboSpikeA-$v.msi" \
      && log "build-a: $v fetched $(stat -c %s "$D/.cache/r3-a/KodeeboSpikeA-$v.msi") bytes sha256 $(sha256sum "$D/.cache/r3-a/KodeeboSpikeA-$v.msi" | cut -c1-16)"
  done
  shutoff; log "build-a: VM shut off (build layer discarded by the next revert)"
  ;;
prep)
  shutoff; $V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null && waitssh admin && waitssh cashier || { log "prep: VM did not come up"; exit 1; }
  throttle
  for f in run-interactive.ps1 installed.ps1 g4-files.ps1; do "$VM" put cashier "$D/guest/$f" "C:/Users/cashier/$f"; done
  for f in setup-sink.ps1 g4-hive.ps1; do "$VM" put admin "$D/guest/$f" "C:/Users/Public/$f"; done
  log "prep: reverted clean-ssh2, booted, throttle $($V blkdeviotune $DOM sda --live | awk '/total_iops_sec /{print $3}') IOPS; sink: $(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\setup-sink.ps1' | tail -1)"
  ;;
install)
  rt=$1; inst=$2; kind=$3; base=$(basename "$inst" | tr ' ' '-')
  "$VM" put cashier "$inst" "C:/Users/cashier/Downloads/$base"
  stamp=$(date +%H%M%S)
  if [ "$kind" = msi ]; then prog=msiexec.exe; args="/i C:\\Users\\cashier\\Downloads\\$base /qn /l*v C:\\Users\\cashier\\install-$rt-$stamp.log"
  else prog="C:\\Users\\cashier\\Downloads\\$base"; args="/S"; fi
  ( sleep 10; $V screenshot $DOM "$D/.cache/g4-uac-$rt-$stamp.ppm" >/dev/null 2>&1 ) &
  r=$(interactive "$prog" "$args" "-wait -timeoutSec 1800" | tr '\n' ' '); wait   # B 1.0.0 took > 600 s (seq1 run 1)
  mkdir -p "$D/evidence/g4"; magick "$D/.cache/g4-uac-$rt-$stamp.ppm" "$D/evidence/g4/install-$rt-$base-at10s.png" 2>/dev/null
  log "install $rt $base: $r | screenshot at +10 s: evidence/g4/install-$rt-$base-at10s.png"
  if [ "$kind" = msi ]; then
    "$VM" get cashier "C:/Users/cashier/install-$rt-$stamp.log" "$D/.cache/install-$rt-$stamp.log" 2>/dev/null
    log "install $rt msi properties: $(iconv -f utf-16 -t utf-8 "$D/.cache/install-$rt-$stamp.log" 2>/dev/null | grep -o -E 'Property\([SC]\): (ALLUSERS|MSIINSTALLPERUSER|ProductVersion|UpgradeCode|ProductCode|Privileged) = [^ ]*' | sort -u | tr '\n' ';')"
    log "install $rt msi lines: $(iconv -f utf-16 -t utf-8 "$D/.cache/install-$rt-$stamp.log" 2>/dev/null | grep -i -E 'MSI_LUA|Installation success or error status|Removal success|RemoveExistingProducts|1603|reboot' | head -6 | tr '\n' ';')"
  fi
  ;;
run)
  rt=$1; shift; log "run $rt $*: $(interactive "$(exe_of "$rt")" "$*" "-wait -timeoutSec 1800" | tail -1)"
  ;;
state)
  rt=$1; label=$2
  interactive "$(exe_of "$rt")" --version -wait >/dev/null; interactive "$(exe_of "$rt")" --check -wait >/dev/null
  log "state $rt $label: $(last "$rt" version.txt) | $(last "$rt" check.txt)"
  log "state $rt $label hive: $(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\g4-hive.ps1' | tr '\n' ' ')"
  log "state $rt $label files: $(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g4-files.ps1' | tr '\n' ' ')"
  ;;
gui)
  # wait for the app's own first-frame line in ready.txt (a fixed sleep missed A's 50-195 s cold start: G4.2a run 1)
  rt=$1; label=$2; rc() { cash "powershell -NoProfile -Command \"if (Test-Path $(data_of "$rt")\\ready.txt) { (Get-Content $(data_of "$rt")\\ready.txt).Count } else { 0 }\"" | tail -1; }
  n0=$(rc); t0=$(date +%s); interactive "$(exe_of "$rt")" "" >/dev/null
  for i in $(seq 1 150); do [ "$(rc)" -gt "${n0:-0}" ] 2>/dev/null && break; sleep 2; done
  log "gui $rt $label: first frame after ~$(( $(date +%s) - t0 )) s (ready.txt lines $n0 -> $(rc))"; sleep 3
  mkdir -p "$D/evidence/g4"; $V screenshot $DOM "$D/.cache/g4-$rt-$label.ppm" >/dev/null && magick "$D/.cache/g4-$rt-$label.ppm" "$D/evidence/g4/$rt-$label.png" && log "gui $rt: evidence/g4/$rt-$label.png"
  ;;
selfupdate)
  rt=$1; inst=$2
  log "selfupdate $rt: $(interactive "$(exe_of "$rt")" "--self-update $inst" -wait | tail -1) | app log: $(last "$rt" selfupdate.txt)"
  ;;
uninstall)
  rt=$1; label=$2
  if [ "$rt" = a ]; then
    code=$(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\g4-hive.ps1' | grep -o -E '\{[0-9A-F-]{36}\}' | head -1)
    r=$(interactive msiexec.exe "/x $code /qn /l*v C:\\Users\\cashier\\uninstall-a.log" -wait | tail -1)
  else
    # double quotes: the path has a space, and single quotes are not quotes on a Windows command line
    # (seq2's two B uninstalls never ran: "Cannot convert value KodeeboSpikeB.exe' to type System.Int32")
    r=$(cash powershell -NoProfile -ExecutionPolicy Bypass -File "$RI" -exe '"C:\Users\cashier\AppData\Local\Programs\kodeebo-spike-b\Uninstall KodeeboSpikeB.exe"' -arguments '"/S"' -wait | tr '\n' ' ')
    # NSIS uninstallers re-launch themselves from %TEMP% and return early: poll until the HKCU Uninstall key is gone
    # and no Un_*/Au_* uninstaller process is left (max 600 s)
    t0=$(date +%s); w="still present after 600 s"
    while [ $(( $(date +%s) - t0 )) -lt 600 ]; do
      p=$(cash "powershell -NoProfile -Command \"\$k=(Get-ChildItem HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall | Where-Object { (Get-ItemProperty \$_.PSPath).DisplayName -match 'KodeeboSpikeB' }).Count; \$u=(Get-Process | Where-Object { \$_.Name -match '^(Un_|Au_)' }).Count; 'k=' + \$k + ' u=' + \$u\"" | tail -1)
      [ "$p" = "k=0 u=0" ] && { w="entry gone, no uninstaller process after $(( $(date +%s) - t0 )) s"; break; }
      sleep 5
    done
    r="$r | poll: $w (last: $p)"
  fi
  [ "$rt" = a ] && sleep 15
  log "uninstall $rt $label: $r"
  log "uninstall $rt $label hive: $(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\g4-hive.ps1' | tr '\n' ' ')"
  log "uninstall $rt $label files: $(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g4-files.ps1' | tr '\n' ' ')"
  ;;
stop)   # stop <rt>: close the app (taskkill as admin; cashier cannot from SSH)
  img=$(basename "$(exe_of "$1" | tr '\\' '/')"); log "stop $1: $(adm "taskkill /F /T /IM $img" | head -1)"
  ;;
shot)
  mkdir -p "$D/evidence/g4"; $V screenshot $DOM "$D/.cache/g4-$1.ppm" >/dev/null && magick "$D/.cache/g4-$1.ppm" "$D/evidence/g4/$1.png" && log "shot: evidence/g4/$1.png"
  ;;
snap-save)
  shutoff; $V snapshot-create-as $DOM "$1" "round 3 temporary: $1 (delete at the end of round 3)" >/dev/null && log "snap-save: $1"
  ;;
snap-boot)
  shutoff; $V snapshot-revert $DOM "$1" && $V start $DOM >/dev/null; t0=$(date +%s)
  waitssh admin || { log "snap-boot $1: no ssh after $(( $(date +%s) - t0 )) s"; exit 1; }; t1=$(date +%s)
  waitlogon || { log "snap-boot $1: ssh after $(( t1 - t0 )) s, but no cashier logon after $(( $(date +%s) - t0 )) s"; exit 1; }
  log "snap-boot $1: ssh after $(( t1 - t0 )) s, cashier Active after $(( $(date +%s) - t0 )) s"   # run 1 gave up here silently (G4-F2 harness)
  [ "${2:-}" = nothrottle ] || throttle
  log "snap-boot: $1 booted, cashier Active, throttle $($V blkdeviotune $DOM sda --live | awk '/total_iops_sec /{print $3}') IOPS"
  ;;
cut)
  rt=$1; inst=$2; off=$3; label=$4
  IFS='|' read -r prog args <<<"$(upgrade_cmd "$inst")"
  interactive "$prog" "$args" >/dev/null
  t0=$(date +%s.%N); sleep "$off"; $V destroy $DOM >/dev/null; t1=$(date +%s.%N)
  log "cut $rt $label: upgrade started, destroyed after $(awk "BEGIN{printf \"%.2f\", $t1 - $t0}") s (target $off s)"
  $V start $DOM >/dev/null; waitssh admin && waitlogon || { log "CUT $rt $label offset=$off RESULT=no-boot"; exit 1; }
  a1=$(appcheck "$rt"); ph=""
  if [[ "$inst" == *.msi ]]; then
    "$VM" get cashier 'C:/Users/cashier/cut.log' "$D/.cache/cut-$rt-$label.log" 2>/dev/null
    ph=$(iconv -f utf-16 -t utf-8 "$D/.cache/cut-$rt-$label.log" 2>/dev/null | grep -E '^Action (start|ended) [0-9:]+: [A-Za-z]+\.' | tail -1)
    [ -z "$ph" ] && ph="no msi log line (cut before msiexec logged)"
    cash 'del C:\Users\cashier\cut.log' >/dev/null 2>&1
  fi
  f1=$(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g4-files.ps1' | grep -E 'dir (present|absent): [^ ]*(KodeeboSpikeA|kodeebo-spike-b)( |$)' | tr '\n' ' ')
  r2=$(interactive "$prog" "$args" "-wait -timeoutSec 1800" | tail -1)   # after a cut this can be a full install (B 1.0.0: 857 s)
  a2=$(appcheck "$rt")
  log "CUT $rt $label offset=$off msi-phase-at-cut: [$ph] after-cut: $a1 [$f1] | rerun installer: [$r2] | after-rerun: $a2"
  ;;
*) sed -n '6,26p' "$0"; exit 2 ;;
esac
