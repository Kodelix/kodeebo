#!/usr/bin/env bash
# PROTOTYPE - NOT FOR PRODUCTION
# Question: Can a standard user upgrade and uninstall A and B per-user without UAC while the encrypted store survives (round 3, G4)?
# Date: 2026-10-18
#
# G4.4 driver: for each line "k=<k> ... offset_s=<s>" of evidence/g4/cut-offsets-<rt>.txt, boot the 1.0.0 snapshot
# (throttled), copy the 1.0.1 installer in, and run "g4.sh cut" at that offset. Results: "CUT ..." lines in .cache/g4-<date>.txt.
# Usage: tools/g4-cuts.sh <rt a|b> <snapshot> <local 1.0.1 installer> [first k] [last k]
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)"
rt=$1; snap=$2; inst=$3; from=${4:-0}; to=${5:-9}
base=$(basename "$inst" | tr ' ' '-'); remote="C:\\Users\\cashier\\Downloads\\$base"
# OFFSETS (file) and PREFIX (label) override the defaults: set 2 for A used cut-offsets-a-set2.txt and labels s2k<k>
offs=${OFFSETS:-$D/evidence/g4/cut-offsets-$rt.txt}; pre=${PREFIX:-k}
grep -E '^k=' "$offs" | while read -r line; do
  k=$(sed -E 's/^k=([0-9]+).*/\1/' <<<"$line"); off=$(sed -E 's/.*offset_s=([0-9.]+).*/\1/' <<<"$line")
  [ "$k" -lt "$from" ] || [ "$k" -gt "$to" ] && continue
  "$D/tools/g4.sh" snap-boot "$snap" </dev/null || continue   # </dev/null: ssh must not eat the loop's input (run 1 stopped after k0)
  "$D/tools/vm.sh" put cashier "$inst" "C:/Users/cashier/Downloads/$base" </dev/null
  "$D/tools/g4.sh" cut "$rt" "$remote" "$off" "$pre$k" </dev/null
done
