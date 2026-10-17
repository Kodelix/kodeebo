#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
# Date: 2026-10-16
#
# G1/G2 driver for one runtime on the VM (see README "Gates" and apps/SPEC.md). Steps:
#   prep    revert clean-ssh2, boot, apply the HDD throttle, copy helper scripts, create the KSPIKE-SINK queue
#   install copy the installer into cashier's Downloads and install it on cashier's desktop (not elevated)
#   print   N x "<app> --print-once" on cashier's desktop, each checked byte for byte at the sink
#   bench   one "<app> --close-bench N" run on cashier's desktop; fetches the bench file
#   kill    N x: start "<app> --kill-loop", wait for commits, kill it at a random moment (taskkill /F, as admin),
#           then "<app> --check"; counts corruptions
# Usage: tools/g2.sh <rt a|b|c> <exe path in VM> <step> [N] [installer local path | bench extra flag] [installer kind msi|exe]
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
VM="$D/tools/vm.sh"
V="virsh -c qemu:///system"
DOM=kodeebo-win10
rt=$1; exe=$2; step=$3; n=${4:-0}
out="$D/.cache/g2-$rt-$step-$(date +%Y%m%d-%H%M%S).txt"
log() { printf '%s\n' "$*" | tee -a "$out"; }
cash() { "$VM" ssh cashier "$@" 2>&1 | tr -d '\r'; }
adm() { "$VM" ssh admin "$@" 2>&1 | tr -d '\r'; }
interactive() {  # interactive <args> [wait]
  local w=""; [ "${2:-}" = wait ] && w="-wait -timeoutSec 1800"
  cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\run-interactive.ps1' -exe "$exe" -arguments "\"$1\"" $w
}
data="C:\\Users\\cashier\\AppData\\Local\\KodeeboSpike\\$rt"

case "$step" in
prep)
  "$VM" ssh admin 'shutdown /s /t 0' >/dev/null 2>&1
  for i in $(seq 1 36); do [ "$($V domstate $DOM)" = "shut off" ] && break; sleep 5; done
  $V snapshot-revert $DOM clean-ssh2 && $V start $DOM >/dev/null
  for i in $(seq 1 40); do "$VM" ssh cashier 'echo up' 2>/dev/null | grep -q up && break; sleep 5; done
  $V blkdeviotune $DOM sda --live --total-iops-sec 100 --total-bytes-sec 83886080
  log "prep: reverted clean-ssh2, booted, throttle $($V blkdeviotune $DOM sda --live | awk '/total_iops_sec /{print $3}') IOPS"
  for f in run-interactive.ps1 installed.ps1 start-measure.ps1; do "$VM" put cashier "$D/guest/$f" "C:/Users/cashier/$f"; done
  for f in setup-sink.ps1 sink-verify.ps1 mem.ps1; do "$VM" put admin "$D/guest/$f" "C:/Users/Public/$f"; done
  "$VM" put admin "$D/apps/a-compose/src/main/resources/receipt.bin" 'C:/Users/Public/golden.bin'
  log "$(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\setup-sink.ps1')"
  ;;
install)
  inst=$5; kind=$6; base=$(basename "$inst")
  s=$(date +%s); "$VM" put cashier "$inst" "C:/Users/cashier/Downloads/$base"; log "copy installer: $(( $(date +%s) - s )) s ($(stat -c %s "$inst") bytes)"
  if [ "$kind" = msi ]; then args="/i C:\\Users\\cashier\\Downloads\\$base /qn /l*v C:\\Users\\cashier\\install-$rt.log"; prog=msiexec.exe
  else args="/S"; prog="C:\\Users\\cashier\\Downloads\\$base"; fi
  log "$(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\run-interactive.ps1' -exe "$prog" -arguments "\"$args\"" -wait)"
  log "$(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\installed.ps1' -name "$(basename "${exe//\\//}" .exe)" -msiLog "C:\\Users\\cashier\\install-$rt.log")"
  $V screenshot $DOM "$D/.cache/g1-$rt-after-install.ppm" >/dev/null && magick "$D/.cache/g1-$rt-after-install.ppm" -resize 1024x "$D/.cache/g1-$rt-after-install.png" && log "screenshot: .cache/g1-$rt-after-install.png"
  ;;
print)
  ok=0; bad=0
  for i in $(seq 1 "$n"); do
    r=$(interactive --print-once wait | grep -o 'program exit code: [0-9-]*')
    v=$(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\sink-verify.ps1' -golden 'C:\Users\Public\golden.bin')
    log "print $i: $r | $(echo "$v" | tr '\n' ' ')"
    echo "$v" | grep -q 'sink bytes=20250 golden bytes=20250 sha256_equal=True' && ok=$((ok+1)) || bad=$((bad+1))
  done
  log "PRINT RESULT: $ok of $n byte-identical at the sink, $bad not"
  log "app print.txt tail: $(cash "powershell -NoProfile -Command Get-Content $data\\print.txt -Tail 3" | tr '\n' ' ')"
  ;;
gui)
  # start-up and memory, same for every runtime: reboot, settle 120 s, FIRST GUI launch (cold), then N warm launches,
  # each killed as admin (cashier cannot kill its own app from the SSH session), then one launch left idle 10 min
  img=$(basename "${exe//\\//}")
  "$VM" ssh admin 'shutdown /r /t 0' >/dev/null 2>&1; sleep 25
  for i in $(seq 1 60); do "$VM" ssh admin 'query user' 2>/dev/null | grep -q -i 'cashier.*Active' && break; sleep 5; done
  log "gui: cashier Active ~$((25 + i * 5)) s after reboot; settling 120 s"; sleep 120
  "$VM" put cashier "$D/guest/start-measure.ps1" 'C:/Users/cashier/start-measure.ps1'
  for k in $(seq 0 "$n"); do
    label=$([ "$k" = 0 ] && echo cold || echo "warm$k")
    log "$(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\start-measure.ps1' -exe "$exe" -rt "$rt" -label "$label" -timeoutSec 300)"
    adm "taskkill /F /T /IM $img" >/dev/null; sleep 5
  done
  r=$(cash powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\cashier\start-measure.ps1' -exe "$exe" -rt "$rt" -label idle -timeoutSec 300); log "$r"
  pid=$(echo "$r" | grep -o 'pid=[0-9]*' | cut -d= -f2)
  sleep 600
  log "memory at 10 min idle:"; log "$(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\mem.ps1' -rootPid "$pid")"
  adm "taskkill /F /T /IM $img" >/dev/null
  ;;
iorebootbench)
  # rebootbench plus an outside sampler of the app processes' total read/write bytes (founder question 1)
  "$VM" ssh admin 'shutdown /r /t 0' >/dev/null 2>&1; sleep 25
  for i in $(seq 1 60); do "$VM" ssh admin 'query user' 2>/dev/null | grep -q -i 'cashier.*Active' && break; sleep 5; done
  log "iorebootbench: cashier Active ~$((25 + i * 5)) s after reboot; settling 120 s"
  sleep 120
  "$VM" put admin "$D/guest/iosample.ps1" 'C:/Users/Public/iosample.ps1'
  img=$(basename "${exe//\\//}" .exe)
  ( "$VM" ssh admin powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\iosample.ps1' -name "$img" 2>&1 | tr -d '\r' > "$D/.cache/iosample-$rt-$(date +%H%M%S).txt" ) &
  sp=$!; sleep 3
  "$0" "$rt" "$exe" bench "$n" "${5:-}" | tee -a "$out"
  wait $sp
  log "io sample: $(ls -t "$D"/.cache/iosample-$rt-*.txt | head -1)"; head -1 "$(ls -t "$D"/.cache/iosample-$rt-*.txt | head -1)" | tee -a "$out"
  ;;
rebootbench)
  # identical cold-start protocol for every runtime: guest reboot (QEMU keeps the live throttle), wait until
  # cashier's console session is Active, settle 120 s, then the bench is the first launch of the app after boot
  "$VM" ssh admin 'shutdown /r /t 0' >/dev/null 2>&1; sleep 25
  for i in $(seq 1 60); do "$VM" ssh admin 'query user' 2>/dev/null | grep -q -i 'cashier.*Active' && break; sleep 5; done
  log "rebootbench: cashier Active ~$((25 + i * 5)) s after reboot; throttle $($V blkdeviotune $DOM sda --live | awk '/total_iops_sec /{print $3}') IOPS; settling 120 s"
  sleep 120
  exec "$0" "$rt" "$exe" bench "$n" "${5:-}"
  ;;
bench)
  extra=${5:-}   # e.g. --warmup
  log "bench args: --close-bench $n $extra"
  log "$(interactive "--close-bench $n $extra" wait)"
  f=$(cash "dir /b /o-d $data\\bench-*.txt" | head -1)
  "$VM" get cashier "C:/Users/cashier/AppData/Local/KodeeboSpike/$rt/$f" "$D/.cache/g2-$rt-$f" && log "bench file: .cache/g2-$rt-$f" && { head -1 "$D/.cache/g2-$rt-$f" | grep warmup; tail -3 "$D/.cache/g2-$rt-$f"; } | tee -a "$out"
  pf=$(cash "dir /b /o-d $data\\phases-*.txt" | head -1)
  [ -n "$pf" ] && "$VM" get cashier "C:/Users/cashier/AppData/Local/KodeeboSpike/$rt/$pf" "$D/.cache/g2-$rt-$pf" && log "phases file: .cache/g2-$rt-$pf" && cat "$D/.cache/g2-$rt-$pf" | tee -a "$out"
  log "sink after bench (last job): $(adm powershell -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Public\sink-verify.ps1' -golden 'C:\Users\Public\golden.bin' -timeoutSec 600 | tr '\n' ' ')"
  ;;
kill)
  img=$(basename "${exe//\\//}")
  corrupt=0; checks=0
  for i in $(seq 1 "$n"); do
    before=$(cash "type $data\\killloop.txt" 2>/dev/null | grep -o '^[0-9]*$' || echo 0); before=${before:-0}
    interactive --kill-loop >/dev/null
    for w in $(seq 1 120); do c=$(cash "type $data\\killloop.txt" 2>/dev/null | grep -o '^[0-9]*$'); [ -n "$c" ] && [ "$c" != "$before" ] && break; sleep 0.5; done
    delay=$(python3 -I -c "import random; print(round(random.uniform(0.2, 2.0), 2))"); sleep "$delay"
    k=$(adm "taskkill /F /T /IM $img" | grep -c SUCCESS)
    rm_ok=$(cash "type $data\\killloop.txt" | grep -o '^[0-9]*$')
    interactive --check wait >/dev/null
    line=$(cash "powershell -NoProfile -Command Get-Content $data\\check.txt -Tail 1")
    checks=$((checks+1))
    echo "$line" | grep -q 'integrity=ok .*consistent=true' || corrupt=$((corrupt+1))
    log "kill $i: delay ${delay}s killed=$k commits_seen=$rm_ok | $line"
  done
  log "KILL RESULT: $checks kills, $corrupt with corruption or inconsistency"
  ;;
*) sed -n '6,14p' "$0"; exit 2 ;;
esac
log "output: $out"
