#!/usr/bin/env bash
# Seed-1006 replays (founder 2026-10-23): 5 NMI cuts held at client:after_mark #1 in each of 4 setups. A store failure is
# a RESULT (recorded, the run goes on); a harness fault (exception, unexpected reboot) stops the run, no retry.
cd "$(dirname "$0")/.."
export PGPASSWORD=spike
st=runs/p4-s104rep.status; echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | wc -l)]" >> $st
V="virsh -c qemu:///system"
stop() { echo "STOPPED $(date '+%F %T'): $1 — VM ($($V domstate kodeebo-win10)) and stores left as they are; no retry" >> $st; exit 1; }
if [ "$($V domstate kodeebo-win10)" = "shut off" ] && [ "$ALREADY_REVERTED" = 1 ]; then
  $V start kodeebo-win10 >/dev/null || stop "virsh start failed"
  for i in $(seq 1 120); do timeout 20 bash harness/p4.sh ad "echo up" 2>/dev/null | grep -q '^up' && break; sleep 5; done
  $V blkdeviotune kodeebo-win10 sda --live --total-iops-sec 100 --total-bytes-sec 83886080; echo "booted the reverted VM, throttled $(date +%T)" >> $st
  bash harness/p4.sh install >> runs/p4-s104rep-install.log 2>&1 || stop "install failed"; echo "install $(date +%T)" >> $st
elif [ "$($V domstate kodeebo-win10)" = "shut off" ]; then
  bash harness/p4.sh up >> $st 2>&1 || stop "p4 up failed"
  bash harness/p4.sh install >> runs/p4-s104rep-install.log 2>&1 || stop "install failed"; echo "install $(date +%T)" >> $st
else stop "the VM was not shut off at the start"; fi
for s in truncslots_bg truncslots deletefile_bg deletefile; do
  .venv/bin/python runs/s104rep.py $s 5 > runs/p4-s104rep-$s.log 2>&1; rc=$?
  echo "$s rc=$rc $(date +%T) $(tail -1 runs/p4-s104rep-$s.log | cut -c1-120) $(grep -o 'transport retries: [0-9]*' runs/p4-s104rep-$s.log | tail -1)" >> $st
  [ $rc -eq 0 ] || stop "$s failed (rc=$rc, see runs/p4-s104rep-$s.log)"
done
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
