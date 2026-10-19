#!/usr/bin/env bash
# P4-F1 probe: does ONE OS crash (NMI bugcheck) from a clean baseline leave Windows at the Recovery screen?
cd "$(dirname "$0")/.."
V="virsh -c qemu:///system"; DOM=kodeebo-win10; P=harness/p4.sh
up() { for i in $(seq 1 ${1:-60}); do timeout 20 bash $P ad "echo up" 2>/dev/null | grep -q up && return 0; sleep 5; done; return 1; }
shot() { $V screenshot $DOM runs/p4-f1-$1.ppm >/dev/null 2>&1; python3 -c "from PIL import Image; Image.open('runs/p4-f1-$1.ppm').save('evidence/phase4/p4-f1-$1.png')"; }
$V destroy $DOM >/dev/null 2>&1; $V snapshot-revert $DOM clean-ssh2; $V start $DOM >/dev/null; up 120 && echo "baseline up $(date +%T)"
bash $P ad 'reg add HKLM\SYSTEM\CurrentControlSet\Control\CrashControl /v NMICrashDump /t REG_DWORD /d 1 /f' >/dev/null
bash $P ad 'reg add HKLM\SYSTEM\CurrentControlSet\Control\CrashControl /v CrashDumpEnabled /t REG_DWORD /d 0 /f' >/dev/null
bash $P ad 'bcdedit /enum {current}' | grep -i -E "recoveryenabled|bootstatuspolicy|identifier"
bash $P ad 'shutdown /r /t 0' >/dev/null 2>&1; sleep 30; up 120 && echo "rebooted clean $(date +%T)"
$V inject-nmi $DOM && echo "NMI $(date +%T)"
if up 60; then echo "case 1: back after one crash $(date +%T)"; else shot after-1-crash; echo "case 1: NOT back after one crash (screenshot)"; fi
