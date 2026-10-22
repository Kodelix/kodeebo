#!/usr/bin/env bash
# Set 4 resumed (founder 2026-10-22): the legs the founder listed after the interruption: S104 on truncate/slots
# (30 power-offs + 10 OS crashes, background check on), the shutdown diagnosis, the first 30 minutes after boot
# (2 untraced boots, 1 with a WPR disk trace) with write volume. The busy-counter legs wait for the founder.
cd "$(dirname "$0")/.."
st=runs/p4-set4.status; echo "--- resume (set 4b) $(date '+%F %T') $(git rev-parse --short HEAD) dirty=[$(git status --porcelain -- . | wc -l)]" >> $st
V="virsh -c qemu:///system"
if [ "$($V domstate kodeebo-win10)" = "shut off" ]; then
  bash harness/p4.sh up >> $st 2>&1
  bash harness/p4.sh install >> runs/p4-set4b-install.log 2>&1; echo "install $(date +%T)" >> $st
else echo "VM already up: continuing" >> $st; fi
r() { name=$1; shift; grep -q "^$name rc=0" $st && return; bash run.sh p4 "$@" > runs/p4-set4-$name.log 2>&1; echo "$name rc=$? $(date +%T)" >> $st; }
r s104                 s104 30 10 truncate slots background counter s4
r s30x-fullold         s30x 1 fullold
r s30x-full            s30x 5 full
r boot-1               bootwatch 30 notrace b1
r boot-2               bootwatch 30 notrace b2
r boot-3               bootwatch 30 trace b3
bash harness/p4.sh down >> $st 2>&1
echo "DONE $(date '+%F %T')" >> $st
