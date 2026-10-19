#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Do A (Compose Desktop) and B (Electron) render and accept Egyptian Arabic correctly on Windows 10 22H2 (G3, S6/S46, OQ22)?
# Date: 2026-10-17
#
# Round 2 G3 driver (README "Round 2"; sheet: apps/ARABIC-SHEET.md). Steps:
#   build-a        revert clean-ssh2, boot UNTHROTTLED, copy JDK/Gradle/WiX zips + apps/a-compose, run guest/build-a.ps1
#                  as admin, fetch the MSI to .cache/r2-a/, then shut down (the next prep reverts: disposable layer)
#   prep           revert clean-ssh2, boot, apply the HDD throttle, copy run-interactive.ps1 and installed.ps1
#   install <rt> <installer> <msi|exe>   install as cashier on cashier's desktop (not elevated)
#   layout         add the Arabic (Egypt) language with the Arabic 101 keyboard for cashier, keep English
#   show <rt> <exe> <--arabic|--arabic-system>   start the sheet on cashier's desktop, wait for ready.txt
#   keys <keys...> send keystrokes with virsh send-key (QEMU key names, e.g. KEY_A KEY_SPACE "KEY_LEFTSHIFT KEY_LEFT")
#   shot <name>    screenshot to evidence/g3/<name>.png (full resolution, no resize)
#   stop <exe image name>  kill the app as admin
# Every step appends to .cache/g3-<date>.txt.
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
VM="$D/tools/vm.sh"
V="virsh -c qemu:///system"
DOM=kodeebo-win10
out="$D/.cache/g3-$(date +%Y%m%d).txt"
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$out"; }
cash() { "$VM" ssh cashier "$@" 2>&1 | tr -d '\r'; }
adm() { "$VM" ssh admin "$@" 2>&1 | tr -d '\r'; }
waitssh() { for i in $(seq 1 60); do "$VM" ssh "$1" 'echo up' 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
shutoff() {
  [ "$($V domstate $DOM)" = "shut off" ] && return 0
  "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1
  for i in $(seq 1 36); do [ "$($V domstate $DOM)" = "shut off" ] && return 0; sleep 5; done
  $V destroy $DOM >/dev/null; log "shutoff: guest did not stop in 180 s; destroyed"
}
revert_boot() { shutoff; $V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null && waitssh admin && waitssh cashier; }

step=${1:?step}; shift
case "$step" in
build-a)
  revert_boot || { log "build-a: VM did not come up"; exit 1; }
  log "build-a: reverted clean-ssh2, booted unthrottled"
  tar -C "$D/apps" --exclude=build --exclude=.gradle --exclude=.kotlin -cf "$D/.cache/r2-a-compose.tar" a-compose
  adm 'powershell -NoProfile -Command "New-Item -ItemType Directory -Force C:\build | Out-Null"' >/dev/null
  for f in "$D/.cache/dl/temurin-jdk21/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip" \
           "$D/.cache/dl/gradle-9.7.0/gradle-9.7.0-bin.zip" "$D/.cache/dl/wix-3.14/wix314-binaries.zip" \
           "$D/.cache/r2-a-compose.tar" "$D/guest/build-a.ps1"; do
    "$VM" put admin "$f" "C:/build/$(basename "$f")"
  done
  adm 'cd C:\build && tar -xf r2-a-compose.tar' >/dev/null
  log "build-a: inputs copied; building (gradle packageMsi)"
  adm 'powershell -NoProfile -ExecutionPolicy Bypass -File C:\build\build-a.ps1' | tee -a "$out"
  mkdir -p "$D/.cache/r2-a"
  "$VM" get admin 'C:/build/a-compose/build/compose/binaries/main/msi/KodeeboSpikeA-1.0.0.msi' "$D/.cache/r2-a/KodeeboSpikeA-1.0.0.msi" \
    && log "build-a: MSI fetched $(stat -c %s "$D/.cache/r2-a/KodeeboSpikeA-1.0.0.msi") bytes sha256 $(sha256sum "$D/.cache/r2-a/KodeeboSpikeA-1.0.0.msi" | cut -c1-16)"
  shutoff; log "build-a: VM shut off (build layer is discarded by the next revert)"
  ;;
prep)
  revert_boot || { log "prep: VM did not come up"; exit 1; }
  $V blkdeviotune $DOM sda --live --total-iops-sec 100 --total-bytes-sec 83886080
  for f in run-interactive.ps1 installed.ps1; do "$VM" put cashier "$D/guest/$f" "C:/Users/cashier/$f"; done
  log "prep: reverted clean-ssh2, booted, throttle $($V blkdeviotune $DOM sda --live | awk '/total_iops_sec /{print $3}') IOPS"
  ;;
install)
  rt=$1; inst=$2; kind=$3; base=$(basename "$inst" | tr ' ' '-')   # no spaces: run-interactive.ps1 splits on them
  "$VM" put cashier "$inst" "C:/Users/cashier/Downloads/$base"
  if [ "$kind" = msi ]; then prog=msiexec.exe; args="/i C:\\Users\\cashier\\Downloads\\$base /qn /l*v C:\\Users\\cashier\\install-$rt.log"
  else prog="C:\\Users\\cashier\\Downloads\\$base"; args="/S"; fi
  log "install $rt: $(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\run-interactive.ps1' -exe "$prog" -arguments "\"$args\"" -wait | tr '\n' ' ')"
  ;;
layout)
  "$VM" put cashier "$D/guest/g3-layout.ps1" 'C:/Users/cashier/g3-layout.ps1'
  log "layout: $(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g3-layout.ps1' | tr '\n' ' ')"
  ;;
show)
  rt=$1; exe=$2; mode=$3; data="C:\\Users\\cashier\\AppData\\Local\\KodeeboSpike\\$rt"
  before=$(cash "powershell -NoProfile -Command \"if (Test-Path $data\\ready.txt) { (Get-Content $data\\ready.txt).Count } else { 0 }\"" | tail -1)
  log "show $rt $mode: $(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\run-interactive.ps1' -exe "$exe" -arguments "\"$mode\"" | head -1)"
  for i in $(seq 1 60); do
    n=$(cash "powershell -NoProfile -Command \"if (Test-Path $data\\ready.txt) { (Get-Content $data\\ready.txt).Count } else { 0 }\"" | tail -1)
    [ "${n:-0}" -gt "${before:-0}" ] && break; sleep 2
  done
  log "show $rt $mode: ready.txt -> $(cash "powershell -NoProfile -Command Get-Content $data\\ready.txt -Tail 1")"
  sleep 12  # A writes ready.txt before its first paint (run 1: a screenshot 4 s later showed only the desktop)
  ;;
keys)
  for k in "$@"; do $V send-key $DOM --codeset linux $k >/dev/null || log "keys: send-key failed for '$k'"; sleep 0.4; done
  log "keys: $*"
  ;;
shot)
  mkdir -p "$D/evidence/g3"
  $V screenshot $DOM "$D/.cache/g3-$1.ppm" >/dev/null && magick "$D/.cache/g3-$1.ppm" "$D/evidence/g3/$1.png" && log "shot: evidence/g3/$1.png"
  ;;
stop)
  log "stop $1: $(adm "taskkill /F /T /IM $1" | head -1)"
  ;;
focus)   # focus <title prefix WITHOUT spaces, e.g. Kodeebo>: AppActivate inside cashier's session (a title with
         # spaces broke the argument passing in run 1). Windows may still refuse; Alt+Tab via keys is the fallback.
  "$VM" put cashier "$D/guest/g3-focus.ps1" 'C:/Users/cashier/g3-focus.ps1'
  cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\run-interactive.ps1' -exe powershell.exe \
    -arguments "\"-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\\Users\\cashier\\g3-focus.ps1 -title '$1'\"" -wait >/dev/null
  log "focus: $(cash 'type %TEMP%\g3-focus.txt')"
  ;;
relogon)   # reboot; cashier auto-logon picks up the language list and the default input method
  "$VM" ssh admin 'shutdown /r /t 0' >/dev/null 2>&1; sleep 25
  for i in $(seq 1 60); do { q=$("$VM" ssh admin 'query user' 2>/dev/null); grep -q -i 'cashier.*Active' <<<"$q"; } && break; sleep 5; done
  log "relogon: cashier Active ~$((25 + i * 5)) s after reboot; throttle $($V blkdeviotune $DOM sda --live | awk '/total_iops_sec /{print $3}') IOPS"
  sleep 30
  ;;
*) sed -n '6,17p' "$0"; exit 2 ;;
esac
