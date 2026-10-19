#!/usr/bin/env bash
# P4-F1 probe 2: repeat the smoke's sequence (power-offs while running, then an OS crash) and note when Windows stops
# at the Recovery screen instead of booting. Each event waits until the VM answers ssh and then 30 s more.
cd "$(dirname "$0")/.."
V="virsh -c qemu:///system"; DOM=kodeebo-win10; P=harness/p4.sh
up() { for i in $(seq 1 ${1:-60}); do timeout 20 bash $P ad "echo up" 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
shot() { $V screenshot $DOM runs/p4-f1-$1.ppm >/dev/null 2>&1; python3 -c "from PIL import Image; Image.open('runs/p4-f1-$1.ppm').save('evidence/phase4/p4-f1-$1.png')"; }
n=0
for ev in ${EVENTS:-power power power nmi power nmi nmi}; do
  n=$((n+1)); sleep 30
  if [ $ev = power ]; then $V destroy $DOM >/dev/null; sleep 2; $V start $DOM >/dev/null; else $V inject-nmi $DOM; fi
  if up 60; then echo "event $n ($ev) $(date +%T): booted"; else shot "event$n-$ev"; echo "event $n ($ev) $(date +%T): NOT booted after 300 s (screenshot)"; exit 0; fi
done
echo "no recovery stop in this sequence"
