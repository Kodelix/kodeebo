#!/usr/bin/env bash
# After set 3 (founder go 2026-10-21): tamper for the four truncate/persist variants, the window test, the regression.
cd "$(dirname "$0")/.."
export PGPASSWORD=spike
(cd sut/server && go build -o server .)
st=runs/p4-linux-set4prep.status
echo "start $(date '+%F %T') $(git rev-parse --short HEAD) uncommitted: $(git status --porcelain -- . | grep -v '^??' | tr '\n' ' ')" >> $st
for v in "truncate file" "persist file" "persist slots" "truncate slots"; do
  set -- $v
  TAMPER_JOURNAL=$1 MARKER_MODE=$2 bash run.sh tamper > runs/p4f3c-tamper-$1-$2.log 2>&1
  echo "tamper $1 $2 rc=$? pass=$(grep -c ' PASS' runs/p4f3c-tamper-$1-$2.log) fail=$(grep -c ' FAIL ' runs/p4f3c-tamper-$1-$2.log) $(date +%T)" >> $st
done
.venv/bin/python harness/bgwindow.py run 5 > runs/p4-bgwindow.log 2>&1; echo "bgwindow rc=$? $(tail -1 runs/p4-bgwindow.log) $(date +%T)" >> $st
.venv/bin/python harness/bgcheck.py > runs/p4-set4prep-bgcheck.log 2>&1; echo "bgcheck rc=$? $(grep -c '"case"' runs/p4-set4prep-bgcheck.log) cases $(date +%T)" >> $st
bash run.sh selftest > runs/p4-set4prep-selftest.log 2>&1; echo "selftest rc=$? $(grep 'GATE' runs/p4-set4prep-selftest.log | tail -1) $(date +%T)" >> $st
bash run.sh phase1 > runs/p4-set4prep-p1.log 2>&1; echo "phase1 rc=$? $(grep 'GATE' runs/p4-set4prep-p1.log | tail -1) $(date +%T)" >> $st
echo DONE >> $st
