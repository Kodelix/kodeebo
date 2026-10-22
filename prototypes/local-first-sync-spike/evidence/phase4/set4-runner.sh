#!/usr/bin/env bash
# Phase 4 leg set 4 (spike runner, gitignored; founder go 2026-10-21): fix 4 with restart counts, S104 on
# truncate/slots (30 power-offs + 10 OS crashes, background check on), the shutdown diagnosis, the first 30 minutes
# after boot (2 untraced boots, 1 with a WPR disk trace), write volume as administrator. Fresh boot of clean-ssh2.
cd "$(dirname "$0")/.."
st=runs/p4-set4.status; echo "--- start $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | wc -l)]" >> $st
V="virsh -c qemu:///system"
if [ "$($V domstate kodeebo-win10)" = "shut off" ]; then
  bash harness/p4.sh up >> $st 2>&1
  bash harness/p4.sh install >> runs/p4-set4-install.log 2>&1; echo "install $(date +%T)" >> $st
else echo "VM already up: continuing" >> $st; fi
r() { name=$1; shift; grep -q "^$name rc=0" $st && return; bash run.sh p4 "$@" > runs/p4-set4-$name.log 2>&1; echo "$name rc=$? $(date +%T)" >> $st; }
r sc24c-thread-g5      sc24c 2 5 thread  s4-thread-g5  5400 n300000
r sc24c-counter-g5     sc24c 2 5 counter s4-counter-g5 5400 n300000
r sc24c-counter-g1     sc24c 2 1 counter s4-counter-g1 5400 n300000
r sc24c-thread-g1      sc24c 2 1 thread  s4-thread-g1  1200 n300000
r sc24c-counter-g1-30k sc24c 1 1 counter s4-counter-g1-30k 5400 n30000
r s104                 s104 30 10 truncate slots background counter s4
r s30x-fullold         s30x 1 fullold
r s30x-full            s30x 5 full
r boot-1               bootwatch 30 notrace b1
r boot-2               bootwatch 30 notrace b2
r boot-3               bootwatch 30 trace b3
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
