#!/usr/bin/env bash
# Set 4 short Linux check (founder go 2026-10-21): fix 4 (BG_MODE=counter) against today's copy, and the S104
# configuration (truncate/slots + background check, fix 4) under the phase 1 kill matrix.
cd "$(dirname "$0")/.."
export PGPASSWORD=spike
st=runs/p4-set4-linuxcheck.status
echo "start $(date '+%F %T') $(git rev-parse --short HEAD) uncommitted: $(git status --porcelain -- . | tr '\n' ' ')" > $st
for m in counter thread; do
  BG_MODE=$m .venv/bin/python harness/bgcheck.py > runs/p4-set4-bgcheck-$m.log 2>&1
  echo "bgcheck $m rc=$? $(grep -c '"case"' runs/p4-set4-bgcheck-$m.log) cases $(date +%T)" >> $st
done
JOURNAL=truncate MARKER_MODE=slots START_CHECK=background BG_MODE=counter BG_IDLE_S=0.3 BG_STEP=16 bash run.sh phase1 > runs/p4-set4-p1-truncslots-bg.log 2>&1
echo "phase1 truncate/slots+bg counter rc=$? $(grep GATE runs/p4-set4-p1-truncslots-bg.log | tail -1) $(date +%T)" >> $st
echo DONE >> $st
