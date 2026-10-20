#!/usr/bin/env bash
# SCRATCH / evidence script (part 2). Usage: bash run.sh <mode> <task> [extra gradle args]   (run from repo root)
# Never run anything inside the desktop spike; Gradle distribution and user home are COPIES under production/session-state/cache.
set -u
MODE=$1; TASK=$2; shift 2
C=production/session-state/cache/module-structure-and-core-boundary/part-2
EV=docs/research/evidence/module-structure-and-core-boundary/part-2
export GRADLE_USER_HOME=$PWD/$C/home
export JAVA_HOME=${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}
START=$(date +%s%N)
OUT="$EV/run-$MODE-$(echo "$TASK" | tr ': ' '__').output.txt"
$C/gradle-9.7.0/bin/gradle -p $EV/spike --no-daemon -Pmode=$MODE $TASK "$@" > "$OUT" 2>&1
RC=$?
END=$(date +%s%N)
echo "mode=$MODE task=$TASK args=$* exit=$RC wall_ms=$(( (END - START) / 1000000 )) at=$(date -u +%FT%TZ)" | tee -a $EV/run-log.txt
