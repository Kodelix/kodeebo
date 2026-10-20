#!/usr/bin/env bash
# S31b: compile S31b.kt with the same local compiler jars and the same already-downloaded libs as S31 (no downloads).
# Classes go to .../part-3/classes-s31b (cache, gitignored). Usage: bash build.sh > build-output.txt 2>&1
set -u
ROOT=/home/kiko/saas-products/kodeebo
HERE="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S31b"
C="$ROOT/production/session-state/cache/jobs-and-outbox/part-3"
OTHER="$ROOT/production/session-state/cache/module-structure-and-core-boundary/part-1/home/caches/modules-2/files-2.1"
f() { find "$OTHER" -name "$1" -type f | head -1; }
STDLIB=$(f kotlin-stdlib-2.4.21.jar); REFLECT=$(f kotlin-reflect-2.4.0.jar)
CCP="$(f kotlin-compiler-embeddable-2.4.21.jar):$STDLIB:$(f kotlin-script-runtime-2.4.21.jar):$REFLECT:$(f kotlin-daemon-embeddable-2.4.21.jar):$(f annotations-13.0.jar):$C/lib/kotlinx-coroutines-core-jvm-1.11.0.jar"
LIBS="$(ls $C/lib/*.jar | tr '\n' ':')$STDLIB:$REFLECT"
rm -rf "$C/classes-s31b"; mkdir -p "$C/classes-s31b"
java -cp "$CCP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -no-stdlib -no-reflect -jvm-target 21 -opt-in kotlin.ExperimentalCoroutinesApi \
  -cp "$LIBS" -d "$C/classes-s31b" "$HERE/S31b.kt"
echo "compile exit=$?"
echo "${LIBS}:$C/classes-s31b:$ROOT/production/session-state/cache/build-and-ops-tooling/part-1/jars/postgresql-42.7.14.jar" > "$C/runtime-classpath-s31b.txt"
ls "$C/classes-s31b" | head -5
