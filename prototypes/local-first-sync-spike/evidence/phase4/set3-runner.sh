#!/usr/bin/env bash
# Phase 4 leg set 3 (spike runner, gitignored). Waits for set 2's DONE (same VM) and for a committed spike tree, then:
# SC-24 options again with the "marker" ready signal, the leading P4-F3 commit variants alternately (3 rounds), S309 8 h.
cd "$(dirname "$0")/.."
st=runs/p4-set3.status; echo "--- queued $(date '+%F %T')" >> $st
until grep -q '^DONE' runs/p4-set2.status; do sleep 60; done
for i in $(seq 1 180); do [ -z "$(git status --porcelain -- . | grep -v '^??')" ] && break; sleep 60; done
echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | grep -v '^??' | wc -l)]" >> $st
V="virsh -c qemu:///system"
if [ "$($V domstate kodeebo-win10)" = "shut off" ]; then
  $V start kodeebo-win10 >/dev/null
  for i in $(seq 1 120); do timeout 20 bash harness/p4.sh ad "echo up" 2>/dev/null | grep -q up && break; sleep 5; done
  $V blkdeviotune kodeebo-win10 sda --live --total-iops-sec 100 --total-bytes-sec 83886080
  bash harness/p4.sh install >> runs/p4-set3-install.log 2>&1; echo "install $(date +%T)" >> $st
else echo "VM already up: continuing" >> $st; fi
r() { name=$1; shift; grep -q "^$name rc=0" $st && return; bash run.sh p4 "$@" > runs/p4-set3-$name.log 2>&1; echo "$name rc=$? $(date +%T)" >> $st; }
r sc24b sc24b 2
r sc24c sc24c 2
for k in 1 2 3; do
  r t-truncate-slots-r$k timings 400 truncate slots r$k
  r t-persist-slots-r$k timings 400 persist slots r$k
  r t-delete-file-r$k timings 400 delete file r$k
done
r s309 s309 8
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
