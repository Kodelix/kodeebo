#!/usr/bin/env bash
# Phase 4 leg set 2 (spike runner, gitignored): fresh boot of the reverted clean-ssh2, install, legs, revert.
cd "$(dirname "$0")/.."
st=runs/p4-set2.status; echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD)" >> $st
V="virsh -c qemu:///system"
if [ "$($V domstate kodeebo-win10)" = "shut off" ]; then
  $V start kodeebo-win10 >/dev/null
  for i in $(seq 1 120); do timeout 20 bash harness/p4.sh ad "echo up" 2>/dev/null | grep -q up && break; sleep 5; done
  $V blkdeviotune kodeebo-win10 sda --live --total-iops-sec 100 --total-bytes-sec 83886080
  bash harness/p4.sh install >> runs/p4-set2-install.log 2>&1; echo "install $(date +%T)" >> $st
else echo "VM already up: continuing" >> $st; fi
r() { name=$1; shift; grep -q "^$name rc=0" $st && return; bash run.sh p4 "$@" > runs/p4-set2-$name.log 2>&1; echo "$name rc=$? $(date +%T)" >> $st; }
r ts01c ts01c
r t-delete-file timings 200 delete file
r t-truncate-file timings 200 truncate file
r t-persist-file timings 200 persist file
r t-delete-slots timings 200 delete slots
r t-persist-slots timings 200 persist slots
r t-truncate-slots timings 200 truncate slots
r sc27-none sc27 200 none
r sc27-paths sc27 200 paths
r sc27-contextual sc27 200 contextual
r sc24b sc24b 2
r sc24c sc24c 2
r ts07b ts07b
r s30x s30x 10
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
