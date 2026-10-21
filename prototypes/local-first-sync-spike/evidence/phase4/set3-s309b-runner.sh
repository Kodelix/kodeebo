#!/usr/bin/env bash
# S309 rerun (spike runner, gitignored): set 3's S309 was interrupted by a host suspend/shutdown (2026-10-21 00:24).
# Fresh boot of the reverted clean-ssh2, install, S309 8 h, revert.
cd "$(dirname "$0")/.."
st=runs/p4-s309b.status; echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | wc -l)]" >> $st
V="virsh -c qemu:///system"
$V start kodeebo-win10 >/dev/null
for i in $(seq 1 120); do timeout 20 bash harness/p4.sh ad "echo up" 2>/dev/null | grep -q up && break; sleep 5; done
$V blkdeviotune kodeebo-win10 sda --live --total-iops-sec 100 --total-bytes-sec 83886080
bash harness/p4.sh install >> runs/p4-s309b-install.log 2>&1; echo "install $(date +%T)" >> $st
bash run.sh p4 s309 8 > runs/p4-s309b.log 2>&1; echo "s309 rc=$? $(date +%T)" >> $st
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
