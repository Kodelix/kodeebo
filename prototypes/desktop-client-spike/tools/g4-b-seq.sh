#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
#
# Round 3 sequences for B, run detached (setsid nohup) so a session end does not cut them. Each writes runs/g4-b-<seq>.status.
#   seq1  prep, install 1.0.0, 20 bills, state, snapshot r3-b-100s, then 3 timed throttled upgrades to 1.0.1 (D)
#   seq2  G4.2a upgrade with 1.0.0 open; G4.2b --self-update; G4.3 uninstall while open and closed
#   seq4  G4.3 rerun of the while-open uninstall (seq2's uninstalls never ran: quoting)
#   seq3  G4.3 deleteAppDataOnUninstall variant: prep, install the variant 1.0.0, 20 bills, open/close the GUI once, uninstall
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"; cd "$D"
T=tools/g4.sh
I100=".cache/build-b/dist-r3-100/KodeeboSpikeB Setup 1.0.0.exe"
I101=".cache/build-b/dist-r3-101/KodeeboSpikeB Setup 1.0.1.exe"
IDEL=".cache/build-b/dist-r3-del/KodeeboSpikeB Setup 1.0.0.exe"
R101='C:\Users\cashier\Downloads\KodeeboSpikeB-Setup-1.0.1.exe'
seq=${1:?seed|seq1|seq2|seq3}
case "$seq" in
seed)   # re-seed: seq1's 1.0.0 install outran the 600 s timeout, so its 20-bill write never ran; r3-b-100 has an empty store
  $T snap-boot r3-b-100; $T run b --close-bench 20; $T state b after-seed; $T snap-save r3-b-100s ;;
seq1)
  $T prep; $T install b "$I100" exe; $T run b --close-bench 20; $T state b after-install-100; $T snap-save r3-b-100s
  for k in 1 2 3; do $T snap-boot r3-b-100s; $T install b "$I101" exe; $T state b "d$k-throttled"; done ;;
seq2)
  $T snap-boot r3-b-100s; $T gui b g42a-100-open; $T install b "$I101" exe; $T shot b-g42a-after-upgrade-while-open; $T state b g42a-after
  $T gui b g43-101-open; $T uninstall b g43-while-open; $T shot b-g43-after-uninstall-while-open
  $T snap-boot r3-b-100s; tools/vm.sh put cashier "$I101" 'C:/Users/cashier/Downloads/KodeeboSpikeB-Setup-1.0.1.exe'
  $T selfupdate b "$R101"; sleep 420; $T state b g42b-after-selfupdate; $T gui b g42b-relaunch
  $T stop b; $T uninstall b g43-closed ;;
seq4)   # G4.3 rerun: seq2's uninstalls never ran (quoting); the closed-app leg was rerun by hand on seq2's 1.0.1 (g43-closed-r2)
  $T snap-boot r3-b-100s; $T gui b g43-100-open-r2; $T uninstall b g43-while-open-r2; $T shot b-g43-after-uninstall-while-open-r2
  $T state b g43-while-open-r2-after ;;
seq3)
  $T prep; $T install b "$IDEL" exe; $T run b --close-bench 20; $T gui b g43-del-open; $T stop b; $T state b g43-del-before
  $T uninstall b g43-del-closed ;;
esac
echo "done $(date +%H:%M:%S)" > "runs/g4-b-$seq.status"
