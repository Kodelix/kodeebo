#!/usr/bin/env bash
# S59b run 2 (tier E, part 5): run 1 was a WRONG TEST - the copy of the spike sits two directories deeper than part 4's, and arch-tests/build.gradle.kts hard-codes the repo root as "../" x6 (Konsist: IllegalArgumentException at KonsistRules.kt:17). Fix = "../" x8 (the ONLY change). Everything cached: --offline.
cd /home/kiko/saas-products/kodeebo
E=docs/research/evidence/module-structure-and-core-boundary/part-5; P4=$E/probes/part-4; C=production/session-state/cache/module-structure-and-core-boundary/part-5
R=$P4/run-gradle982.sh; OFF=--offline; KT="-Plint=ktlint2 -PktlintMain=io.github.ktlint.core.Main"
STACK=":arch-tests:test :graph-check:assertModuleGraph :syntax24:ktlint2Syntax :syntax24:ktlint2Fixture :syntax24:ktlint2Help :syntax24:ktlint2Empty :syntax24:ktlint2Control"
keep() { mkdir -p $E/results-run2/$1; cp $C/build/arch-tests/test-results/test/*.xml $E/results-run2/$1/ 2>/dev/null; }
bash $R violations offline-first $OFF :arch-tests:test --continue; keep violations-1
bash $R clean clean-1 $OFF :arch-tests:test --continue; keep clean-1
bash $R strict strict-compile $OFF compileKotlin --continue
bash $R clean ktlint2-alpha4 $OFF $KT :syntax24:ktlint2Syntax :syntax24:ktlint2Fixture :syntax24:ktlint2Format --continue
bash $R violations stack-cold $OFF -PwithGraphPlugin=1 $KT $STACK --continue; keep stack-cold
bash $R violations stack-warm $OFF -PwithGraphPlugin=1 $KT $STACK --continue; keep stack-warm
bash $R violations notrun-probes $OFF -Pprobe=true :arch-tests:test --tests NotRunProbes --continue; keep notrun-probes
for d in violations-1 clean-1 stack-warm notrun-probes; do for f in $E/results-run2/$d/*.xml; do echo "$d $(basename $f): $(grep -o -m1 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*" errors="[0-9]*"' $f)"; done; done
grep -h -c "IllegalArgumentException" $P4/run-*.output.txt | tr '\n' ' '; echo
