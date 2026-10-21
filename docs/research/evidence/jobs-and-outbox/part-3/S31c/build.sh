#!/usr/bin/env bash
# S31c: compile S31c.kt with the Kotlin 2.4.21 compiler jars found READ-ONLY in other sessions' caches and the jars re-fetched into
# production/session-state/cache/jobs-and-outbox/part-3/lib (download-output.txt). No downloads here. Usage: bash build.sh > build-output.txt 2>&1
set -u
ROOT=/home/kiko/saas-products/kodeebo
HERE="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S31c"
C="$ROOT/production/session-state/cache/jobs-and-outbox/part-3"
OTHER="$ROOT/production/session-state/cache/module-structure-and-core-boundary/part-1/home/caches/modules-2/files-2.1"
f() { find "$OTHER" -name "$1" -type f | head -1; }
STDLIB=$(f kotlin-stdlib-2.4.21.jar); REFLECT=$(f kotlin-reflect-2.4.0.jar)
PGJDBC=$(find "$ROOT/production/session-state/cache/build-and-ops-tooling/part-1/jars" -name postgresql-42.7.14.jar | head -1)
CCP="$(f kotlin-compiler-embeddable-2.4.21.jar):$STDLIB:$(f kotlin-script-runtime-2.4.21.jar):$REFLECT:$(f kotlin-daemon-embeddable-2.4.21.jar):$(f annotations-13.0.jar):$C/lib/kotlinx-coroutines-core-jvm-1.11.0.jar"
LIBS="$(ls $C/lib/*.jar | tr '\n' ':')$STDLIB:$REFLECT"
rm -rf "$C/classes-s31c"; mkdir -p "$C/classes-s31c"
java -cp "$CCP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect -jvm-target 21 -opt-in kotlin.ExperimentalCoroutinesApi \
  -cp "$LIBS" -d "$C/classes-s31c" "$HERE/S31c.kt"
echo "compile exit=$?"
echo "${LIBS}:$C/classes-s31c:$PGJDBC" > "$C/runtime-classpath-s31c.txt"
ls "$C/classes-s31c" | head -3
