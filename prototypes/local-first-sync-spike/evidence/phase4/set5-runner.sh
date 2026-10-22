#!/usr/bin/env bash
# Set 5 (founder 2026-10-22): S104 rerun on truncate/slots (30 power-offs + 10 OS crashes, background check fix 4),
# then fix 4 under the rush profile and at a sale every 5 s, today's gate (1 s, 64 pages) and the short one (0.2 s,
# 16 pages), >= 200 sales each, checks back to back, the sampler alongside; then the /full diagnosis and the three
# boot watches again with the throttle checked (set 4b's were invalid).
# Founder rule: if anything faults, STOP: no automatic retries, the VM and the stores are left as they are.
cd "$(dirname "$0")/.."
st=runs/p4-set5.status; echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | wc -l)]" >> $st
V="virsh -c qemu:///system"
stop() { echo "STOPPED $(date '+%F %T'): $1 — VM ($($V domstate kodeebo-win10)) and stores left as they are; no retry" >> $st; exit 1; }
if [ "$($V domstate kodeebo-win10)" = "shut off" ]; then
  bash harness/p4.sh up >> $st 2>&1 || stop "p4 up failed"
  bash harness/p4.sh install >> runs/p4-set5-install.log 2>&1 || stop "install failed"; echo "install $(date +%T)" >> $st
else stop "the VM was not shut off at the start"; fi
r() { name=$1; shift; bash run.sh p4 "$@" > runs/p4-set5-$name.log 2>&1; rc=$?
  echo "$name rc=$rc $(date +%T) $(grep -o 'transport retries: [0-9]*' runs/p4-set5-$name.log | tail -1)" >> $st
  grep -q UnexpectedReboot runs/p4-set5-$name.log && stop "$name: the VM rebooted on its own ($(grep -o 'BootId [0-9]* -> [0-9]*' runs/p4-set5-$name.log | tail -1))"
  [ $rc -eq 0 ] || stop "$name failed (rc=$rc, see runs/p4-set5-$name.log)"; }
r s104      s104 30 10 truncate slots background counter s5
r rush-i1   sc24r rush-i1  rush 1.0 64 200
r rush-i02  sc24r rush-i02 rush 0.2 16 200
r gap5-i1   sc24r gap5-i1  gap  1.0 64 200 5
r gap5-i02  sc24r gap5-i02 gap  0.2 16 200 5
r s30x-fullold  s30x 1 fullold        # set 4b's run was invalid: the VM was mid-reboot after the failed S104 start
r boot-1        bootwatch 30 notrace b1   # set 4b's boot watches ran unthrottled: rerun with the throttle checked
r boot-2        bootwatch 30 notrace b2
r boot-3        bootwatch 30 trace b3
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
