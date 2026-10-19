#!/usr/bin/env bash
# P4-F1 probe 3: (a) from clean-ssh2, two power cuts each 10 s after the VM answers ssh -> Recovery screen?
# (b) the same after `bcdedit /set {current} recoveryenabled No` + `bootstatuspolicy IgnoreAllFailures`.
cd "$(dirname "$0")/.."
V="virsh -c qemu:///system"; DOM=kodeebo-win10; P=harness/p4.sh
up() { for i in $(seq 1 ${1:-60}); do timeout 20 bash $P ad "echo up" 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
shot() { $V screenshot $DOM runs/p4-f1-$1.ppm >/dev/null 2>&1; python3 -c "from PIL import Image; Image.open('runs/p4-f1-$1.ppm').save('evidence/phase4/p4-f1-$1.png')"; }
base() { $V destroy $DOM >/dev/null 2>&1; $V snapshot-revert $DOM clean-ssh2; $V start $DOM >/dev/null; up 120; }
cuts() { # $1 label, $2 delay after ssh answers
  for n in 1 2 3; do sleep $2; $V destroy $DOM >/dev/null; sleep 2; $V start $DOM >/dev/null
    if up 60; then echo "$1 cut $n (+$2 s after ssh) $(date +%T): booted"; else shot "$1-cut$n"; echo "$1 cut $n (+$2 s after ssh) $(date +%T): NOT booted after 300 s (Recovery? screenshot)"; return; fi
  done; }
base && echo "(a) baseline up"; cuts a 10
base && echo "(b) baseline up"
bash $P ad 'bcdedit /set {current} recoveryenabled No' ; bash $P ad 'bcdedit /set {current} bootstatuspolicy IgnoreAllFailures'
bash $P ad 'bcdedit /enum {current}' | grep -i -E "recoveryenabled|bootstatuspolicy"
bash $P ad 'shutdown /r /t 0' >/dev/null 2>&1; sleep 40; up 60; cuts b 10
