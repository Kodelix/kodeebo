#!/usr/bin/env bash
cd "$(dirname "$0")/.."
export PGPASSWORD=spike
st=runs/p4-linux-set4prep.status
echo "--- bgwindow final run $(date '+%F %T') $(git rev-parse --short HEAD) (classification fixed: sent-in-sync, fault moment = first sign)" >> $st
.venv/bin/python harness/bgwindow.py run 5 > runs/p4-bgwindow-final.log 2>&1; echo "bgwindow rc=$? $(tail -1 runs/p4-bgwindow-final.log) $(date +%T)" >> $st
echo DONE-FINAL >> $st
