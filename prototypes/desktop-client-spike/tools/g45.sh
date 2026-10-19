#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does a launcher outside the program folder that re-runs the last good installer make the app start after every
# power cut during an update, with nobody reinstalling (round 3, G4.5)?
# Date: 2026-10-18
#
# G4.5 driver (README "G4.5"). Uses tools/g4.sh for snapshots; every step appends to .cache/g4-<date>.txt.
#   setup <rt>              boot the round 3 1.0.0 snapshot (a: r3-a-100, b: r3-b-100s), install the launcher, stage 1.0.0 and
#                           1.0.1 with their manifests, journal ok 1.0.0, one launch (must say healthy), save r3-<rt>-100L
#   addstartup <rt>         put the launcher in the cashier's Startup folder INSIDE r3-<rt>-100L (clean shutdown, re-snapshot).
#                           L0 run 1 created it after logon: Explorer's delayed Startup pass still ran it during the update,
#                           and the entry did not run after the cut (the new file was likely not on disk yet)
#   cut <rt> <offset> <label>   boot r3-<rt>-100L (the launcher starts the app at logon; wait for its first frame, as at a
#                           venue where the app runs when the update starts), start "-update 1.0.1", wait for "installer starting",
#                           power off after <offset> s, start + throttle at once, wait up to 1800 s for a new first-frame
#                           line (the launcher starts the app at logon), then --version, --check, files, launcher log
#   cuts <rt> [first] [last]    cut for each line of the runtime's G4.4 offsets file (labels L<k>); OFFSETS and PREFIX
#                           override (A supplementary set: OFFSETS=evidence/g4/cut-offsets-a-g45.txt PREFIX=M)
#   refresh <rt>            copy the current launcher into r3-<rt>-100L (before-repair line for the supplementary set)
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
VM="$D/tools/vm.sh"; G4="$D/tools/g4.sh"
V="virsh -c qemu:///system"; DOM=kodeebo-win10
out="$D/.cache/g4-$(date +%Y%m%d).txt"
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$out"; }
cash() { "$VM" ssh cashier "$@" 2>&1 | tr -d '\r'; }
adm() { "$VM" ssh admin "$@" 2>&1 | tr -d '\r'; }
throttle() { $V blkdeviotune $DOM sda --live --total-iops-sec 100 --total-bytes-sec 83886080; }
waitssh() { for i in $(seq 1 180); do "$VM" ssh "$1" 'echo up' 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
waitlogon() { for i in $(seq 1 120); do { q=$("$VM" ssh admin 'query user' 2>/dev/null); grep -q -i 'cashier.*Active' <<<"$q"; } && return 0; sleep 5; done; return 1; }
RI='C:\Users\cashier\run-interactive.ps1'
interactive() { cash powershell -NoProfile -ExecutionPolicy Bypass -File "$RI" -exe "$1" -arguments "\"$2\"" ${3:-}; }
LH='C:\Users\cashier\AppData\Local\KodeeboSpikeLauncher'
q() { cash powershell -NoProfile -ExecutionPolicy Bypass -File "$LH\\$1\\g45-q.ps1" -rt "$1" -what "${@:2}" | tail -1; }
data_of() { echo "C:\\Users\\cashier\\AppData\\Local\\KodeeboSpike\\$1"; }
# marker count per file (ready.txt: first_frame_ms=, version.txt: version=, check.txt: integrity=), retried until numeric.
# Not a line count: a cut leaves NUL bytes where an unflushed line was, with no newline, so the next line joins it (L0 run 3)
mk() { case "$1" in ready.txt) echo first_frame_ms= ;; version.txt) echo version= ;; check.txt) echo integrity= ;; esac; }
cnt() { local r f; for i in 1 2 3 4 5 6; do f="$(data_of "$1")\\$2"; r=$(cash "powershell -NoProfile -Command \"if (Test-Path $f) { ([regex]::Matches([IO.File]::ReadAllText('$f'), '$(mk "$2")')).Count } else { 0 }\"" | tail -1); [[ "$r" =~ ^[0-9]+$ ]] && { echo "$r"; return; }; sleep 5; done; echo NaN; }
# last marker record of a file (from the marker to the end of its line), NULs ignored
lastl() { local f; f="$(data_of "$1")\\$2"; cash "powershell -NoProfile -Command \"if (Test-Path $f) { \$m = [regex]::Matches([IO.File]::ReadAllText('$f'), '$(mk "$2")[^\\r\\n]*'); if (\$m.Count) { \$m[\$m.Count-1].Value } else { 'no record' } } else { 'no $2' }\"" | tail -1; }
exe_of() { case "$1" in a) echo 'C:\Users\cashier\AppData\Local\KodeeboSpikeA\KodeeboSpikeA.exe' ;; b) echo 'C:\Users\cashier\AppData\Local\Programs\kodeebo-spike-b\KodeeboSpikeB.exe' ;; esac; }
# per runtime: base snapshot, local installers, remote names, program-folder manifest per version (round 3 state lines)
cfg() {
  case "$1" in
    a) BASE=r3-a-100; I0="$D/.cache/r3-a/KodeeboSpikeA-1.0.0.msi"; I1="$D/.cache/r3-a/KodeeboSpikeA-1.0.1.msi"
       N0=KodeeboSpikeA-1.0.0.msi; N1=KodeeboSpikeA-1.0.1.msi; F0=201; B0=143017262; F1=201; B1=143017261
       OFFS="$D/evidence/g4/cut-offsets-a-set2.txt" ;;
    b) BASE=r3-b-100s; I0="$D/.cache/build-b/dist-r3-100/KodeeboSpikeB Setup 1.0.0.exe"; I1="$D/.cache/build-b/dist-r3-101/KodeeboSpikeB Setup 1.0.1.exe"
       N0=KodeeboSpikeB-Setup-1.0.0.exe; N1=KodeeboSpikeB-Setup-1.0.1.exe; F0=250; B0=449842551; F1=250; B1=449842551
       OFFS="$D/evidence/g4/cut-offsets-b.txt" ;;
  esac
}
# wait for a new first-frame line in ready.txt (max $2 s); prints seconds waited or "none"
waitframe() {
  local rt=$1 max=$2 n0=$3 t0; t0=$(date +%s)
  while [ $(( $(date +%s) - t0 )) -lt "$max" ]; do
    [ "$(cnt "$rt" ready.txt)" -gt "$n0" ] 2>/dev/null && { echo $(( $(date +%s) - t0 )); return 0; }
    sleep 5
  done; echo none; return 1
}
step=${1:?setup|cut|cuts}; shift
case "$step" in
setup)
  rt=$1; cfg "$rt"
  "$G4" snap-boot "$BASE" || exit 1
  cash "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path $LH\\$rt | Out-Null\"" >/dev/null
  for f in kspike-launcher.ps1 g45-q.ps1; do "$VM" put cashier "$D/guest/$f" "C:/Users/cashier/AppData/Local/KodeeboSpikeLauncher/$rt/$f"; done
  "$VM" put cashier "$I0" "C:/Users/cashier/Downloads/$N0"; "$VM" put cashier "$I1" "C:/Users/cashier/Downloads/$N1"
  L="powershell -NoProfile -ExecutionPolicy Bypass -File $LH\\$rt\\kspike-launcher.ps1 -rt $rt"
  cash "$L -stage C:\\Users\\cashier\\Downloads\\$N0 -version 1.0.0 -files $F0 -bytes $B0" >/dev/null
  cash "$L -stage C:\\Users\\cashier\\Downloads\\$N1 -version 1.0.1 -files $F1 -bytes $B1" >/dev/null
  cash "$L -init 1.0.0" >/dev/null
  n0=$(cnt "$rt" ready.txt)
  interactive powershell.exe "-NoProfile -ExecutionPolicy Bypass -File $LH\\$rt\\kspike-launcher.ps1 -rt $rt" -wait >/dev/null
  w=$(waitframe "$rt" 1200 "$n0")
  log "g45 setup $rt: launcher log: $(q "$rt" log -n 4) | first frame after ${w} s | journal: $(q "$rt" journal)"
  img=$(basename "$(exe_of "$rt" | tr '\\' '/')"); adm "taskkill /F /T /IM $img" >/dev/null
  "$G4" snap-save "r3-$rt-100L"
  ;;
addstartup)
  rt=$1
  "$G4" snap-boot "r3-$rt-100L" nothrottle || exit 1
  cnt "$rt" ready.txt > "$D/.cache/g45-$rt-ready0"   # ready.txt lines in the snapshot: a logon launch adds one
  log "g45 addstartup $rt: $(q "$rt" startup-on); ready.txt lines in snapshot: $(cat "$D/.cache/g45-$rt-ready0")"
  "$G4" shot "g45-$rt-addstartup" >/dev/null
  "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1
  for i in $(seq 1 60); do [ "$($V domstate $DOM)" = "shut off" ] && break; sleep 5; done
  $V snapshot-delete $DOM "r3-$rt-100L" >/dev/null && $V snapshot-create-as $DOM "r3-$rt-100L" "G4.5 temporary: launcher + Startup entry (delete when G4.5 reports)" >/dev/null && log "g45 addstartup $rt: r3-$rt-100L re-saved with the Startup entry"
  ;;
refresh)   # put the current guest/kspike-launcher.ps1 into r3-<rt>-100L (clean shutdown, re-snapshot)
  rt=$1
  "$G4" snap-boot "r3-$rt-100L" nothrottle || exit 1
  "$VM" put cashier "$D/guest/kspike-launcher.ps1" "C:/Users/cashier/AppData/Local/KodeeboSpikeLauncher/$rt/kspike-launcher.ps1"
  h=$(cash "powershell -NoProfile -Command \"(Get-FileHash $LH\\$rt\\kspike-launcher.ps1 -Algorithm SHA256).Hash.Substring(0,16)\"" | tail -1)
  # the Startup entry launches the app at this logon: let it draw, close it, and record the snapshot's new frame baseline
  wr=$(waitframe "$rt" 900 "$(cat "$D/.cache/g45-$rt-ready0")")
  img=$(basename "$(exe_of "$rt" | tr '\\' '/')"); adm "taskkill /F /T /IM $img" >/dev/null; sleep 5
  cnt "$rt" ready.txt > "$D/.cache/g45-$rt-ready0"; log "g45 refresh $rt: logon launch drew after ${wr} s; frame baseline now $(cat "$D/.cache/g45-$rt-ready0")"
  "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1
  for i in $(seq 1 60); do [ "$($V domstate $DOM)" = "shut off" ] && break; sleep 5; done
  $V snapshot-delete $DOM "r3-$rt-100L" >/dev/null && $V snapshot-create-as $DOM "r3-$rt-100L" "G4.5 temporary: launcher (before-repair line) + Startup entry (delete when G4.5 reports)" >/dev/null && log "g45 refresh $rt: launcher sha256 $h (local $(sha256sum "$D/guest/kspike-launcher.ps1" | cut -c1-16)); r3-$rt-100L re-saved"
  ;;
cut)
  rt=$1; off=$2; label=$3; cfg "$rt"
  "$G4" snap-boot "r3-$rt-100L" || exit 1
  wb=$(waitframe "$rt" 1800 "$(cat "$D/.cache/g45-$rt-ready0")")   # the launcher's logon launch: app up before the update
  log "cut45 $rt $label: before the update, app first frame after ${wb} s from logon"
  n0=$(cnt "$rt" ready.txt); m0=$(q "$rt" loglines)
  interactive powershell.exe "-NoProfile -ExecutionPolicy Bypass -File $LH\\$rt\\kspike-launcher.ps1 -rt $rt -update 1.0.1" >/dev/null
  ts=$(date +%s); until [ "$(q "$rt" started)" = yes ]; do [ $(( $(date +%s) - ts )) -gt 300 ] && { log "CUT45 $rt $label: launcher never logged 'installer starting'"; exit 1; }; sleep 1; done
  t0=$(date +%s.%N); sleep "$off"; $V destroy $DOM >/dev/null; t1=$(date +%s.%N)
  log "cut45 $rt $label: installer started (+$(( $(date +%s) - ts )) s after launch incl. offset), destroyed after $(awk "BEGIN{printf \"%.2f\", $t1 - $t0}") s (target $off s)"
  $V start $DOM >/dev/null; throttle   # throttle at once: the launcher's repair at logon runs on the HDD-class disk
  tb=$(date +%s)
  waitssh cashier || { log "CUT45 $rt $label offset=$off RESULT=no-boot"; exit 1; }
  # baseline after the reboot, not n0: lines written before the cut may be lost with the power (not flushed)
  nb=$(cnt "$rt" ready.txt)
  w=$(waitframe "$rt" 3600 "$nb"); tw=$(( $(date +%s) - tb ))   # 1800 s missed A's frame in L0 run 2 (repair 271 s, then a cold start)
  "$G4" shot "g45-$rt-$label" >/dev/null
  pr=$(cash "powershell -NoProfile -Command \"Get-Process KodeeboSpike* -ErrorAction SilentlyContinue | ForEach-Object { \$_.Name + ' ' + \$_.Id + ' ' + \$_.StartTime.ToString('HH:mm:ss') + ' title=' + \$_.MainWindowTitle }\"" | tr '\n' ';')
  ph=""; [ "$rt" = a ] && ph=$(q "$rt" msiphase)
  ll=$(q "$rt" logsince -mark "$m0")
  # app state: --version and --check, accepted only if new lines appear (G4-F6)
  nv=$(cnt "$rt" version.txt); nc=$(cnt "$rt" check.txt)
  interactive "$(exe_of "$rt")" --version -wait >/dev/null; interactive "$(exe_of "$rt")" --check -wait >/dev/null
  [ "$(cnt "$rt" version.txt)" -gt "${nv:-0}" ] 2>/dev/null && v=$(lastl "$rt" version.txt) || v="NO NEW version LINE"
  [ "$(cnt "$rt" check.txt)" -gt "${nc:-0}" ] 2>/dev/null && c=$(lastl "$rt" check.txt) || c="NO NEW check LINE"
  f=$(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g4-files.ps1' | grep -E 'dir (present|absent): [^ ]*(KodeeboSpikeA|kodeebo-spike-b)( |$)' | tr '\n' ' ')
  if [ "$w" = none ]; then res=FAIL-no-first-frame; else res=PASS-app-started; fi
  log "CUT45 $rt $label offset=$off RESULT=$res first-frame=${w}s-after-ssh (boot to frame ${tw} s) procs=[$pr] shot=evidence/g4/g45-$rt-$label.png msi-phase-at-cut: [$ph] | app: [$v] [$c] [$f] | journal: [$(q "$rt" journal)] | launcher: [$ll]"
  ;;
cuts)
  rt=$1; from=${2:-0}; to=${3:-9}; cfg "$rt"; OFFS=${OFFSETS:-$OFFS}; pre=${PREFIX:-L}   # supplementary A set: cut-offsets-a-g45.txt, labels M<k>
  grep -E '^k=' "$OFFS" | while read -r line; do
    k=$(sed -E 's/^k=([0-9]+).*/\1/' <<<"$line"); off=$(sed -E 's/.*offset_s=([0-9.]+).*/\1/' <<<"$line")
    [ "$k" -lt "$from" ] || [ "$k" -gt "$to" ] && continue
    "$0" cut "$rt" "$off" "$pre$k" </dev/null
  done
  ;;
*) sed -n '6,15p' "$0"; exit 2 ;;
esac
