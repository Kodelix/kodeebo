#!/usr/bin/env bash
# Set 6 (founder 2026-10-23): truncate dropped; re-measure the crash-safe commit options without it, 3 alternating
# rounds of 400 sales each: delete/file (today), delete/slots, persist/file, persist/slots. A TIMING leg: a line goes
# into runs/p4-set5.status first (the ADR-0015 session stops its host spikes when it sees one). Stop at the first fault,
# no automatic retries.
cd "$(dirname "$0")/.."
st=runs/p4-set6.status; echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | wc -l)]" >> $st
echo "TIMING-LEG start $(date '+%F %T'): set 6 commit-option timings (about 1 h 20); host spikes must stop" >> runs/p4-set5.status
V="virsh -c qemu:///system"
stop() { echo "STOPPED $(date '+%F %T'): $1 — VM ($($V domstate kodeebo-win10)) and stores left as they are; no retry" >> $st; echo "TIMING-LEG stopped $(date '+%F %T') (set 6)" >> runs/p4-set5.status; exit 1; }
if [ "$($V domstate kodeebo-win10)" = "shut off" ] && [ "$ALREADY_REVERTED" = 1 ]; then
  $V start kodeebo-win10 >/dev/null || stop "virsh start failed"
  for i in $(seq 1 120); do timeout 20 bash harness/p4.sh ad "echo up" 2>/dev/null | grep -q '^up' && break; sleep 5; done
  $V blkdeviotune kodeebo-win10 sda --live --total-iops-sec 100 --total-bytes-sec 83886080; echo "booted the reverted VM, throttled $(date +%T)" >> $st
  bash harness/p4.sh install >> runs/p4-set6-install.log 2>&1 || stop "install failed"; echo "install $(date +%T)" >> $st
else stop "the VM was not shut off and freshly reverted at the start"; fi
r() { name=$1; shift; bash run.sh p4 "$@" > runs/p4-set6-$name.log 2>&1; rc=$?
  echo "$name rc=$rc $(date +%T) $(grep -o 'transport retries: [0-9]*' runs/p4-set6-$name.log | tail -1)" >> $st
  grep -q UnexpectedReboot runs/p4-set6-$name.log && stop "$name: the VM rebooted on its own"
  [ $rc -eq 0 ] || stop "$name failed (rc=$rc, see runs/p4-set6-$name.log)"; }
for k in 1 2 3; do
  r t-delete-file-s6r$k   timings 400 delete file s6r$k
  r t-delete-slots-s6r$k  timings 400 delete slots s6r$k
  r t-persist-file-s6r$k  timings 400 persist file s6r$k
  r t-persist-slots-s6r$k timings 400 persist slots s6r$k
done
bash harness/p4.sh down >> $st 2>&1
echo "TIMING-LEG end $(date '+%F %T') (set 6)" >> runs/p4-set5.status
echo "DONE $(date '+%F %T')" >> $st
