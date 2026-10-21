#!/usr/bin/env bash
# After set 3 (founder go 2026-10-21): tamper for the four truncate/persist variants, the window test, the regression.
cd "$(dirname "$0")/.."
export PGPASSWORD=spike
(cd sut/server && go build -o server .)
st=runs/p4-linux-set4prep.status; echo "--- resume (tamper done above; bgwindow fixed: late-page target, pacing, unchanged-from-fault check)" >> $st
echo "start $(date '+%F %T') $(git rev-parse --short HEAD) uncommitted: $(git status --porcelain -- . | grep -v '^??' | tr '\n' ' ')" >> $st
.venv/bin/python harness/bgwindow.py run 5 > runs/p4-bgwindow.log 2>&1; echo "bgwindow rc=$? $(tail -1 runs/p4-bgwindow.log) $(date +%T)" >> $st
.venv/bin/python harness/bgcheck.py > runs/p4-set4prep-bgcheck.log 2>&1; echo "bgcheck rc=$? $(grep -c '"case"' runs/p4-set4prep-bgcheck.log) cases $(date +%T)" >> $st
bash run.sh selftest > runs/p4-set4prep-selftest.log 2>&1; echo "selftest rc=$? $(grep 'GATE' runs/p4-set4prep-selftest.log | tail -1) $(date +%T)" >> $st
bash run.sh phase1 > runs/p4-set4prep-p1.log 2>&1; echo "phase1 rc=$? $(grep 'GATE' runs/p4-set4prep-p1.log | tail -1) $(date +%T)" >> $st
echo DONE >> $st
