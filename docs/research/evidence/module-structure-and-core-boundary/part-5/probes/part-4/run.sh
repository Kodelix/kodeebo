#!/usr/bin/env bash
# SCRATCH / evidence script (part 4). Usage: bash run.sh <mode> <label> <gradle args...>   (run from repo root)
# TAG env var selects a fresh build/project-cache dir (used for the cold run: nothing is deleted).
# Gradle distribution + user home: part-2 cache (read-write). Build output and project cache go to the gitignored part-4 cache, never into evidence.
set -u
MODE=$1; LABEL=$2; shift 2
C=production/session-state/cache/module-structure-and-core-boundary
EV=docs/research/evidence/module-structure-and-core-boundary/part-4
export GRADLE_USER_HOME=$PWD/$C/part-2/home
export JAVA_HOME=${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}
mkdir -p $C/part-4/build${TAG:-}
START=$(date +%s%N)
OUT="$EV/run-$MODE-$LABEL.output.txt"
$C/part-2/gradle-9.7.0/bin/gradle -p $EV/spike --no-daemon --project-cache-dir $PWD/$C/part-4/project-cache${TAG:-} -Pmode=$MODE -PbuildRoot=$PWD/$C/part-4/build${TAG:-} -Pkotlin.project.persistent.dir=$PWD/$C/part-4/kotlin-dir${TAG:-} "$@" > "$OUT" 2>&1
RC=$?
END=$(date +%s%N)
echo "mode=$MODE label=$LABEL args=$* exit=$RC wall_ms=$(( (END - START) / 1000000 )) at=$(date -u +%FT%TZ)" | tee -a $EV/run-log.txt
