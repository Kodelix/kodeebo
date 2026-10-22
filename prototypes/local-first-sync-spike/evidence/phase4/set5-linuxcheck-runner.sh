#!/usr/bin/env bash
cd "$(dirname "$0")/.."
export PGPASSWORD=spike
st=runs/p4-set5-linuxcheck.status
echo "start $(date '+%F %T') $(git rev-parse --short HEAD) uncommitted: $(git status --porcelain -- . | tr '\n' ' ')" > $st
.venv/bin/python harness/repeatcheck.py > runs/p4-set5-repeatcheck.log 2>&1; echo "repeatcheck rc=$? $(tail -1 runs/p4-set5-repeatcheck.log) $(date +%T)" >> $st
for m in counter thread; do BG_MODE=$m .venv/bin/python harness/bgcheck.py > runs/p4-set5-bgcheck-$m.log 2>&1; echo "bgcheck $m rc=$? $(grep -c '"case"' runs/p4-set5-bgcheck-$m.log) cases $(date +%T)" >> $st; done
bash run.sh selftest > runs/p4-set5-selftest.log 2>&1; echo "selftest rc=$? $(grep GATE runs/p4-set5-selftest.log | tail -1) $(date +%T)" >> $st
echo DONE >> $st
