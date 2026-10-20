#!/usr/bin/env bash
# S59b (tier E, part 5): part-4's combined suite on Gradle 9.8.2, the same invocations as part-4 run-log.txt (all --offline), run from the repo root.
set -u
R=docs/research/evidence/module-structure-and-core-boundary/part-5/probes/part-4/run-gradle982.sh
OFF=""; KT="-Plint=ktlint2 -PktlintMain=io.github.ktlint.core.Main"
STACK=":arch-tests:test :graph-check:assertModuleGraph :syntax24:ktlint2Syntax :syntax24:ktlint2Fixture :syntax24:ktlint2Help :syntax24:ktlint2Empty :syntax24:ktlint2Control"
bash $R violations offline-first $OFF :arch-tests:test --continue
bash $R clean clean-1 $OFF :arch-tests:test --continue
bash $R strict strict-compile $OFF compileKotlin --continue
bash $R clean ktlint2-alpha4 $OFF $KT :syntax24:ktlint2Syntax :syntax24:ktlint2Fixture :syntax24:ktlint2Format --continue
bash $R violations stack-cold $OFF -PwithGraphPlugin=1 $KT $STACK --continue
bash $R violations stack-warm $OFF -PwithGraphPlugin=1 $KT $STACK --continue
bash $R violations notrun-probes $OFF -Pprobe=true :arch-tests:test --tests NotRunProbes --continue
