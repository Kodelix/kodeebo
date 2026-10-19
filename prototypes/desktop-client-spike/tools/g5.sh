#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does the M1 migration survive a power cut at every step, and does the app refuse a store it cannot trust (round 4, G5)?
# Date: 2026-10-19
#
# Round 4 driver (README "Round 4"). Uses tools/g4.sh for prep, install, snapshots and screenshots; every step appends to
# .cache/g4-<date>.txt (one run log for rounds 3 and 4).
#   build-a                 revert clean-ssh2, build A 1.0.1 (schema 1) and 1.0.2 (schema 2) on the VM, fetch to .cache/r4-a/
#   build-b                 build B 1.0.1 and 1.0.2 on the host (.cache/build-b/dist-r4-10x)
#   base <rt>               prep, install 1.0.1, 20 bills, --check, copy the 1.0.1 program folder to old101\<rt>, install 1.0.2
#                           (never started), save r4-<rt>-s1v2 (temporary)
#   cut <rt> <point> <label>    boot r4-<rt>-s1v2, hold.txt = point, start 1.0.2 --check, wait for hold-reached.txt, power off,
#                           boot (throttled), probe the files, run 1.0.2 --check (completes), then the old 1.0.1 --check
#                           (must refuse a schema-2 store), probe again; one CUT5 line per cut
#   cuts <rt>               the 6 points x 2 runs (labels H<point>-<run>)
#   control <rt>            the migration with no hold (timing and the plain path)
#   ts05 <rt> | ts03 <rt> | ts06 <rt>   tamper legs (README "Round 4", G5.2-G5.4)
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
exe_of() { case "$1" in a) echo 'C:\Users\cashier\AppData\Local\KodeeboSpikeA\KodeeboSpikeA.exe' ;; b) echo 'C:\Users\cashier\AppData\Local\Programs\kodeebo-spike-b\KodeeboSpikeB.exe' ;; esac; }
old_of() { case "$1" in a) echo 'C:\Users\cashier\old101\a\KodeeboSpikeA.exe' ;; b) echo 'C:\Users\cashier\old101\b\KodeeboSpikeB.exe' ;; esac; }
progdir() { case "$1" in a) echo 'C:\Users\cashier\AppData\Local\KodeeboSpikeA' ;; b) echo 'C:\Users\cashier\AppData\Local\Programs\kodeebo-spike-b' ;; esac; }
data_of() { echo "C:\\Users\\cashier\\AppData\\Local\\KodeeboSpike\\$1"; }
probe() { cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g5-probe.ps1' -rt "$1" | tail -1; }
mut() { local rt=$1; shift; cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\g5-mut.ps1' -rt "$rt" "$@" | tail -1; }
# marker counts and last records (round 3 G4.5: NUL bytes after a cut join lines, so count markers, not lines)
mk() { case "$1" in check.txt) echo '(integrity=|open-failed:)' ;; migration.txt) echo '\d{13} ' ;; events.txt) echo 'event=' ;; keyattempts.txt) echo 'n=' ;; serve.txt) echo '(start|ok|read failed|end) ' ;; esac; }
cnt() { local r fl; for i in 1 2 3 4 5 6; do fl="$(data_of "$1")\\$2"; r=$(cash "powershell -NoProfile -Command \"if (Test-Path $fl) { ([regex]::Matches([IO.File]::ReadAllText('$fl'), '$(mk "$2")')).Count } else { 0 }\"" | tail -1); [[ "$r" =~ ^[0-9]+$ ]] && { echo "$r"; return; }; sleep 5; done; echo NaN; }
# records after the first <skip> markers, one line, " || " separated
since() { local fl; fl="$(data_of "$1")\\$2"; cash "powershell -NoProfile -Command \"if (Test-Path $fl) { \$m = [regex]::Matches([IO.File]::ReadAllText('$fl'), '$(mk "$2")[^\\r\\n]*'); (\$m | Select-Object -Skip $3 | ForEach-Object { \$_.Value }) -join ' || ' } else { 'no $2' }\"" | tail -1; }
run() {   # run <rt> <exe> <args> <file> -> the records the run added to <file>
  local rt=$1 ex=$2 a=$3 fl=$4 n0; n0=$(cnt "$rt" "$fl")
  interactive "$ex" "$a" "-wait -timeoutSec 1800" >/dev/null
  echo "[$(since "$rt" "$fl" "$n0")]"
}
step=${1:?build-a|build-b|base|cut|cuts|control|ts05|ts03|ts06}; shift
case "$step" in
build-a)
  BUILDS=${BUILDS:-1.0.1:1,1.0.2:2}   # version:schemaMax pairs; the journal leg adds 1.0.3:2
  [ "$($V domstate $DOM)" = "shut off" ] || { "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1; sleep 60; $V destroy $DOM >/dev/null 2>&1; }
  $V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null && waitssh admin || { log "g5 build-a: VM did not come up"; exit 1; }
  log "g5 build-a: reverted clean-ssh2, booted unthrottled"
  tar -C "$D/apps" --exclude=build --exclude=.gradle --exclude=.kotlin -cf "$D/.cache/r4-a-compose.tar" a-compose
  adm 'powershell -NoProfile -Command "New-Item -ItemType Directory -Force C:\build | Out-Null"' >/dev/null
  for x in "$D/.cache/dl/temurin-jdk21/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip" \
           "$D/.cache/dl/gradle-9.7.0/gradle-9.7.0-bin.zip" "$D/.cache/dl/wix-3.14/wix314-binaries.zip" \
           "$D/.cache/r4-a-compose.tar" "$D/guest/build-a-r4.ps1"; do "$VM" put admin "$x" "C:/build/$(basename "$x")"; done
  adm 'cd C:\build && tar -xf r4-a-compose.tar' >/dev/null
  log "g5 build-a: building 1.0.1 (schema 1) and 1.0.2 (schema 2)"
  adm "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\build\\build-a-r4.ps1 -builds $BUILDS" | tee -a "$out"
  mkdir -p "$D/.cache/r4-a"
  for v in $(tr ',' '\n' <<<"$BUILDS" | cut -d: -f1); do
    "$VM" get admin "C:/build/out/KodeeboSpikeA-$v.msi" "$D/.cache/r4-a/KodeeboSpikeA-$v.msi" \
      && log "g5 build-a: $v fetched $(stat -c %s "$D/.cache/r4-a/KodeeboSpikeA-$v.msi") bytes sha256 $(sha256sum "$D/.cache/r4-a/KodeeboSpikeA-$v.msi" | cut -c1-16)"
  done
  "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1; for i in $(seq 1 36); do [ "$($V domstate $DOM)" = "shut off" ] && break; sleep 5; done
  log "g5 build-a: VM shut off (build layer discarded by the next revert)"
  ;;
build-b)
  cp "$D/apps/b-electron/main.js" "$D/.cache/build-b/main.js"
  cmp -s "$D/apps/b-electron/package.json" "$D/.cache/build-b/package.json" || { log "g5 build-b: package.json differs from apps/b-electron"; exit 1; }
  for p in $(tr ',' ' ' <<<"${BUILDS:-1.0.1:1,1.0.2:2}"); do
    v=${p%:*}; sm=${p#*:}
    ( cd "$D/.cache/build-b" && npx --no-install electron-builder --win --x64 --publish never -c.directories.output="dist-r4-${v//./}" \
        -c.extraMetadata.version="$v" -c.extraMetadata.kspikeSchema="$sm" ) > "$D/.cache/build-b-r4-$v.log" 2>&1
    e="$D/.cache/build-b/dist-r4-${v//./}/KodeeboSpikeB Setup $v.exe"
    [ -f "$e" ] && log "g5 build-b: $v (schema $sm) $(stat -c %s "$e") bytes sha256 $(sha256sum "$e" | cut -c1-16)" || { log "g5 build-b: $v FAILED (.cache/build-b-r4-$v.log)"; exit 1; }
  done
  ;;
base)
  rt=$1
  case "$rt" in
    a) I1="$D/.cache/r4-a/KodeeboSpikeA-1.0.1.msi"; I2="$D/.cache/r4-a/KodeeboSpikeA-1.0.2.msi"; k=msi ;;
    b) I1="$D/.cache/build-b/dist-r4-101/KodeeboSpikeB Setup 1.0.1.exe"; I2="$D/.cache/build-b/dist-r4-102/KodeeboSpikeB Setup 1.0.2.exe"; k=exe ;;
  esac
  "$G4" prep || exit 1
  for x in g5-probe.ps1 g5-mut.ps1; do "$VM" put cashier "$D/guest/$x" "C:/Users/cashier/$x"; done
  "$G4" install "$rt" "$I1" "$k"
  interactive "$(exe_of "$rt")" "--close-bench 20" "-wait -timeoutSec 1800" >/dev/null
  log "g5 base $rt: 1.0.1 check $(run "$rt" "$(exe_of "$rt")" --check check.txt) | probe: $(probe "$rt")"
  cash "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force C:\\Users\\cashier\\old101 | Out-Null; Copy-Item -Recurse -Force '$(progdir "$rt")' C:\\Users\\cashier\\old101\\$rt; (Get-ChildItem -Recurse -File C:\\Users\\cashier\\old101\\$rt).Count\"" | tail -1 | sed "s/^/$(date +%H:%M:%S) g5 base $rt: old101 files /" | tee -a "$out"
  "$G4" install "$rt" "$I2" "$k"
  log "g5 base $rt: 1.0.2 installed, not started; probe: $(probe "$rt")"
  "$G4" snap-save "r4-$rt-s1v2"
  ;;
cut|control)
  if [ "$step" = cut ]; then rt=$1; point=$2; label=$3; else rt=$1; point=none; label=control; fi
  "$G4" snap-boot "r4-$rt-s1v2" || exit 1
  p0=$(probe "$rt"); m0=$(cnt "$rt" migration.txt); c0=$(cnt "$rt" check.txt); e0=$(cnt "$rt" events.txt)
  if [ "$point" != none ]; then
    for i in 1 2 3 4 5; do mut "$rt" -what hold -point "$point" >/dev/null; probe "$rt" | grep -q 'hold.txt=absent' || break; sleep 3; done
    probe "$rt" | grep -q 'hold.txt=absent' && { log "CUT5 $rt $label point=$point RESULT=HARNESS-hold.txt-not-written"; exit 1; }
    interactive "$(exe_of "$rt")" --check >/dev/null
    ts=$(date +%s)
    until cash "powershell -NoProfile -Command \"if (Test-Path $(data_of "$rt")\\hold-reached.txt) { Get-Content $(data_of "$rt")\\hold-reached.txt }\"" | grep -q "point=$point"; do
      [ $(( $(date +%s) - ts )) -gt 1200 ] && { log "CUT5 $rt $label point=$point RESULT=HOLD-NOT-REACHED (1200 s) | migration: $(since "$rt" migration.txt "$m0") | events: $(since "$rt" events.txt "$e0")"; exit 1; }
      sleep 2
    done
    $V destroy $DOM >/dev/null
    log "cut5 $rt $label: hold point $point reached after $(( $(date +%s) - ts )) s; powered off"
    $V start $DOM >/dev/null; throttle
    waitssh cashier && waitlogon || { log "CUT5 $rt $label RESULT=no-boot"; exit 1; }
    p1=$(probe "$rt"); mut "$rt" -what nohold >/dev/null
  else
    p1=$p0
  fi
  r2=$(run "$rt" "$(exe_of "$rt")" --check check.txt)
  mg=$(since "$rt" migration.txt "$m0")
  p2=$(probe "$rt")
  r3=$(run "$rt" "$(old_of "$rt")" --check check.txt)
  p3=$(probe "$rt"); ev=$(since "$rt" events.txt "$e0")
  s2=$(grep -o -E 'store\.db=[0-9]+/[0-9A-F]+' <<<"$p2"); s3=$(grep -o -E 'store\.db=[0-9]+/[0-9A-F]+' <<<"$p3")
  ok=PASS
  grep -q 'integrity=ok' <<<"$r2" && grep -q 'schema=2' <<<"$r2" && grep -q 'outbox=20' <<<"$r2" || ok=FAIL
  grep -q -E 'outbox_sha=' <<<"$r2" || ok=FAIL
  grep -q 'newer than this app' <<<"$r3" || ok=FAIL
  [ "$s2" = "$s3" ] || ok=FAIL
  grep -q 'store.db.premigrate=absent' <<<"$p2" || ok=FAIL
  log "CUT5 $rt $label point=$point RESULT=$ok | files before: [$p0] | after the cut: [$p1] | 1.0.2 --check: $r2 | migration: [$mg] | files after 1.0.2: [$p2] | old 1.0.1 --check: $r3 | files after old: [$p3] | events: [$ev]"
  ;;
cuts)
  rt=$1
  for run_ in 1 2; do
    for pt in before-copy during-copy after-copy mid-transaction after-commit after-delete; do "$0" cut "$rt" "$pt" "H$pt-$run_" </dev/null; done
  done
  ;;
ts05)
  rt=$1
  "$G4" snap-boot "r4-$rt-s1v2" || exit 1
  log "g5 ts05 $rt: migrate first: $(run "$rt" "$(exe_of "$rt")" --check check.txt) | $(probe "$rt")"
  for kind in wrong truncated empty; do
    e0=$(cnt "$rt" events.txt); pa=$(probe "$rt"); km=$(mut "$rt" -what key -kind "$kind")
    r=$(run "$rt" "$(exe_of "$rt")" --check check.txt); pb=$(probe "$rt")
    sa=$(grep -o -E 'store\.db=[0-9]+/[0-9A-F]+' <<<"$pa"); sb=$(grep -o -E 'store\.db=[0-9]+/[0-9A-F]+' <<<"$pb")
    kb=$(grep -o -E 'key\.bin=[0-9]+/[0-9A-F]+' <<<"$pb"); ok=PASS
    grep -q 'open-failed' <<<"$r" || ok=FAIL; [ "$sa" = "$sb" ] || ok=FAIL
    grep -q "$(grep -o -E 'sha=[0-9A-F]+' <<<"$km" | head -1 | cut -c5-)" <<<"$kb" || ok=FAIL   # key.bin not replaced by the app
    log "TS05 $rt $kind RESULT=$ok | $km | --check: $r | files before: [$pa] after: [$pb] | events: [$(since "$rt" events.txt "$e0")]"
    mut "$rt" -what key -kind restore >/dev/null
  done
  e0=$(cnt "$rt" events.txt); pa=$(probe "$rt")
  r=$(run "$rt" "$(exe_of "$rt")" "--key-attempts 100" keyattempts.txt); pb=$(probe "$rt")
  ok=PASS; grep -q 'opened=0 failed=100' <<<"$r" || ok=FAIL
  [ "$(grep -o -E 'store\.db=[0-9]+/[0-9A-F]+' <<<"$pa")" = "$(grep -o -E 'store\.db=[0-9]+/[0-9A-F]+' <<<"$pb")" ] || ok=FAIL
  log "TS05 $rt attempts100 RESULT=$ok | $r | files before: [$pa] after: [$pb]"
  log "TS05 $rt after restore: $(run "$rt" "$(exe_of "$rt")" --check check.txt)"
  ;;
ts03)
  rt=$1
  for case_ in page3-closed page1-closed journal-closed page3-running; do
    if [ "$case_" = journal-closed ]; then
      "$G4" snap-boot "r4-$rt-s1v2" || exit 1
      mut "$rt" -what hold -point mid-transaction >/dev/null; interactive "$(exe_of "$rt")" --check >/dev/null
      ts=$(date +%s); until cash "powershell -NoProfile -Command \"if (Test-Path $(data_of "$rt")\\hold-reached.txt) { Get-Content $(data_of "$rt")\\hold-reached.txt }\"" | grep -q 'point=mid-transaction'; do [ $(( $(date +%s) - ts )) -gt 1200 ] && exit 1; sleep 2; done
      $V destroy $DOM >/dev/null; $V start $DOM >/dev/null; throttle; waitssh cashier && waitlogon || exit 1
      mut "$rt" -what nohold >/dev/null
      pj=$(probe "$rt")
      mm=$(mut "$rt" -what flip -file store.db-journal -offset 600 -count 64)
    else
      "$G4" snap-boot "r4-$rt-s1v2" || exit 1
      log "g5 ts03 $rt $case_: migrate first: $(run "$rt" "$(exe_of "$rt")" --check check.txt)"
      pj=$(probe "$rt")
      case "$case_" in
        page3-closed) mm=$(mut "$rt" -what flip -file store.db -offset 8392 -count 64) ;;   # inside page 3 (4096-byte pages)
        page1-closed) mm=$(mut "$rt" -what flip -file store.db -offset 200 -count 64) ;;    # inside page 1, after the header
        page3-running)
          s0=$(cnt "$rt" serve.txt)
          interactive "$(exe_of "$rt")" "--serve 60" >/dev/null; sleep 20
          mm=$(mut "$rt" -what flip -file store.db -offset 8392 -count 64); sleep 50
          mm="$mm | serve: [$(since "$rt" serve.txt "$s0")]" ;;
      esac
    fi
    e0=$(cnt "$rt" events.txt); pa=$(probe "$rt")
    r=$(run "$rt" "$(exe_of "$rt")" --check check.txt); pb=$(probe "$rt")
    r2=$(run "$rt" "$(exe_of "$rt")" --check check.txt)
    log "TS03 $rt $case_ | before tamper: [$pj] | $mm | files: [$pa] | --check: $r | files after: [$pb] | second --check: $r2 | events: [$(since "$rt" events.txt "$e0")]"
  done
  ;;
base3)   # r4-<rt>-s1v<n>: r4-<rt>-s1v2 plus 1.0.<n> (n=3: schema 2 and --spill-hold; n=4: plus the G5-F4 copy-aside fix)
  rt=$1; n=${2:-3}
  case "$rt" in
    a) I3="$D/.cache/r4-a/KodeeboSpikeA-1.0.$n.msi"; k=msi ;;
    b) I3="$D/.cache/build-b/dist-r4-10$n/KodeeboSpikeB Setup 1.0.$n.exe"; k=exe ;;
  esac
  "$G4" snap-boot "r4-$rt-s1v2" || exit 1
  for x in g5-probe.ps1 g5-mut.ps1; do "$VM" put cashier "$D/guest/$x" "C:/Users/cashier/$x"; done   # current helpers
  "$G4" install "$rt" "$I3" "$k"
  log "g5 base3 $rt: 1.0.$n installed; $(probe "$rt")"
  "$G4" snap-save "r4-$rt-s1v$n"
  ;;
ts03j)   # TS-03c journal leg: spill, cut before COMMIT, then (flip|noflip) the hot journal, then --check
  rt=$1; how=$2; n=${3:-3}
  "$G4" snap-boot "r4-$rt-s1v$n" || exit 1
  log "g5 ts03j $rt $how: migrate first: $(run "$rt" "$(exe_of "$rt")" --check check.txt)"
  e0=$(cnt "$rt" events.txt)
  for i in 1 2 3 4 5; do mut "$rt" -what hold -point spill-before-commit >/dev/null; probe "$rt" | grep -q 'hold.txt=absent' || break; sleep 3; done
  interactive "$(exe_of "$rt")" --spill-hold >/dev/null
  ts=$(date +%s); until cash "powershell -NoProfile -Command \"if (Test-Path $(data_of "$rt")\\hold-reached.txt) { Get-Content $(data_of "$rt")\\hold-reached.txt }\"" | grep -q 'point=spill-before-commit'; do [ $(( $(date +%s) - ts )) -gt 1200 ] && { log "TS03J $rt $how RESULT=HOLD-NOT-REACHED"; exit 1; }; sleep 2; done
  sp=$(cash "powershell -NoProfile -Command \"Get-Content $(data_of "$rt")\\spill.txt -Tail 1\"" | tail -1)
  $V destroy $DOM >/dev/null; $V start $DOM >/dev/null; throttle; waitssh cashier && waitlogon || exit 1
  mut "$rt" -what nohold >/dev/null
  pj=$(probe "$rt")
  if [ "$how" = flip ]; then mm=$(mut "$rt" -what flip -file store.db-journal -offset 600 -count 64); else mm="no flip"; fi
  pa=$(probe "$rt")
  r=$(run "$rt" "$(exe_of "$rt")" --check check.txt); pb=$(probe "$rt")
  r2=$(run "$rt" "$(exe_of "$rt")" --check check.txt)
  log "TS03J $rt $how v1.0.$n | $sp | after the cut: [$pj] | $mm | files: [$pa] | --check: $r | files after: [$pb] | second --check: $r2 | events: [$(since "$rt" events.txt "$e0")]"
  ;;
ts06)
  rt=$1
  "$G4" snap-boot "r4-$rt-s1v2" || exit 1
  log "g5 ts06 $rt: migrate first: $(run "$rt" "$(exe_of "$rt")" --check check.txt)"
  s0=$(cnt "$rt" serve.txt)
  interactive "$(exe_of "$rt")" "--serve 40" >/dev/null; sleep 20
  dm=$(mut "$rt" -what delete -file store.db); sleep 30
  log "TS06 $rt while-running | $dm | serve: [$(since "$rt" serve.txt "$s0")] | files: [$(probe "$rt")]"
  e0=$(cnt "$rt" events.txt)
  dm=$(mut "$rt" -what delete -file store.db)
  r=$(run "$rt" "$(exe_of "$rt")" --check check.txt); pb=$(probe "$rt")
  ok=PASS; grep -q 'store missing' <<<"$r" || ok=FAIL; grep -q 'store.db=absent' <<<"$pb" || ok=FAIL
  log "TS06 $rt closed RESULT=$ok | $dm | --check: $r | files after: [$pb] | events: [$(since "$rt" events.txt "$e0")]"
  ;;
*) sed -n '6,20p' "$0"; exit 2 ;;
esac
