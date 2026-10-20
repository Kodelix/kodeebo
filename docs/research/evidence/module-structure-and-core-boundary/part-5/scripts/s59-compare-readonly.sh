#!/usr/bin/env bash
# Read-only comparison of the Gradle 9.8.2 re-runs with the 9.7.0 records of parts 3 and 4 (no Gradle is run).
cd /home/kiko/saas-products/kodeebo
EV=docs/research/evidence/module-structure-and-core-boundary; E=$EV/part-5; P4=$E/probes/part-4; C=production/session-state/cache/module-structure-and-core-boundary/part-5
echo "## run-log 9.8.2"; sed -E 's/ args=.* exit=/ exit=/' $P4/run-log.txt | cut -c1-110
echo "## run-log 9.7.0 (part 4, the same labels)"; sed -E 's/ args=.* exit=/ exit=/' $EV/part-4/run-log.txt | grep -E "offline-first|clean-1|strict-compile|ktlint2-alpha4|stack-|notrun" | cut -c1-110
echo "## junit 9.8.2 (final state of the build dir = last arch-tests run)"
for f in $C/build/arch-tests/test-results/test/*.xml; do echo "$(basename $f): $(grep -o -m1 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*" errors="[0-9]*"' $f)"; done
echo "## part-4 summaries (9.7.0)"; head -8 $EV/part-4/results/violations-1.summary.txt; head -4 $EV/part-4/results/clean-1.summary.txt
echo "## graph/ktlint markers 9.8.2 stack-warm"; grep -h -E "KTLINT_EXIT|assertModuleGraph|Illegal|violat" $P4/run-violations-stack-warm.output.txt | head -14 | cut -c1-180
echo "## 9.7.0 stack-warm"; grep -h -E "KTLINT_EXIT" $EV/part-4/run-violations-stack-warm.output.txt | head -8
echo "## warnings in 9.8.2 suite outputs"; grep -h -i -E "deprecat|^w: |unsupported|not supported|warning:" $P4/run-*.output.txt | sort | uniq -c | sort -rn | head -10 | cut -c1-240
echo "## warnings in S10/S11/S12/S31 outputs"; grep -h -i -E "deprecat|^w: |unsupported|not supported|warning:" $E/s54a-run2-online-fill.output.txt $E/s54b-run-s11.output.txt $E/s54b-run-s12-run3.output.txt $E/s59a-run-s31.output.txt | sort | uniq -c | sort -rn | head -8 | cut -c1-240
echo "## S31 key lines 9.8.2 / 9.7.0"; grep -E "identical|YES|components" $E/s59a-run-s31.output.txt | cut -c1-120; echo --; grep -E "identical|YES|components" $EV/part-3/s31-run2-output.txt | cut -c1-120
echo "## S31 exit sequence 9.8.2 vs 9.7.0"; grep -E "^exit=" $E/s59a-run-s31.output.txt | sed -E 's/ wall_ms=[0-9]+//' | tr '\n' ' '; echo; grep -E "^exit=" $EV/part-3/s31-run2-output.txt | sed -E 's/ wall_ms=[0-9]+//' | tr '\n' ' '; echo
echo "## sizes"; du -sh $E | tail -n 1; find $E -name .gradle -o -name .kotlin -o -name build -type d | head -3
