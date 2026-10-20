#!/usr/bin/env bash
# S10 - multi-module Gradle structure probe (tier E). Run: bash scripts/run-s10.sh  (from the part-1 evidence dir)
# Gradle 9.7.0 distribution is REUSED READ-ONLY from part 2's cache; modules-2 is COPIED (local copy, not a download).
# RUN 1 had network (kotlin-dsl pulled ~104 MB of Kotlin 2.4.0 artifacts, see F110); RUN 2 onward uses --offline.
# Usage: bash scripts/run-s10.sh > s10-run2-output.txt   (run 1 output: s10-run1-output.txt, WRONG RUN: accessor flag missing)
set -u
REPO=/home/kiko/saas-products/kodeebo
EV=$REPO/docs/research/evidence/module-structure-and-core-boundary/part-1
CACHE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-1
P2=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-2
GRADLE=$P2/gradle-9.7.0/bin/gradle
export GRADLE_USER_HOME=$CACHE/home
WORK=$CACHE/work-s10
mkdir -p "$GRADLE_USER_HOME/caches" "$WORK"
if [ ! -d "$GRADLE_USER_HOME/caches/modules-2" ]; then cp -r "$P2/home/caches/modules-2" "$GRADLE_USER_HOME/caches/modules-2"; fi
rm -rf "$WORK"/*; cp -r "$EV/s10/project/." "$WORK/"
echo "date: $(date -u +%FT%TZ)"; echo "java: $(java -version 2>&1 | head -1)"
echo "cache size before: $(du -sb "$GRADLE_USER_HOME" | cut -f1) bytes"
g() { echo; echo "### gradle $*"; local s=$(date +%s%N); "$GRADLE" -p "$WORK" --offline --console=plain "$@" 2>&1 | tail -n ${TAIL:-40}; echo "exit=${PIPESTATUS[0]} wall_ms=$(( ($(date +%s%N) - s) / 1000000 ))"; }
"$GRADLE" --offline --version 2>&1 | sed -n 1,12p
TAIL=60 g updateKotlinAbi
echo "cache size after first build: $(du -sb "$GRADLE_USER_HOME" | cut -f1) bytes"
echo; echo "### ABI dump files"; (cd "$WORK" && find . -path ./build-logic -prune -o -name '*.api' -print -o -name '*.dump' -print | sort; cat platform/tenancy/api/*.api 2>/dev/null)
TAIL=15 g build
echo; echo "######## B1: leak of an implementation-only dependency"
cp "$EV/s10/violations/Leak.kt" "$WORK/app/src/main/kotlin/kodeebo/app/Leak.kt"; TAIL=12 g :app:compileKotlin; rm "$WORK/app/src/main/kotlin/kodeebo/app/Leak.kt"
echo; echo "######## B2: explicit API strict violation"
cp "$EV/s10/violations/Violation.kt" "$WORK/platform/tenancy/src/main/kotlin/kodeebo/tenancy/Violation.kt"; TAIL=12 g :platform:tenancy:compileKotlin; rm "$WORK/platform/tenancy/src/main/kotlin/kodeebo/tenancy/Violation.kt"
echo; echo "######## B3: ABI change without updating the dump"
cp "$EV/s10/violations/AbiChange.kt" "$WORK/platform/tenancy/src/main/kotlin/kodeebo/tenancy/AbiChange.kt"; TAIL=25 g checkKotlinAbi; TAIL=8 g updateKotlinAbi; (cd "$WORK" && git diff --no-index --stat /dev/null platform/tenancy/api 2>/dev/null | tail -3; cat platform/tenancy/api/*.api)
TAIL=8 g checkKotlinAbi
echo; echo "######## C: configuration cache and timing (all tasks up to date unless noted)"
TAIL=6 g build --no-configuration-cache
TAIL=6 g build --configuration-cache
TAIL=6 g build --configuration-cache
echo "-- touch one source file in tenancy (non-ABI change), with config cache"
echo "// touch" >> "$WORK/platform/tenancy/src/main/kotlin/kodeebo/tenancy/TenantId.kt"
TAIL=6 g build --configuration-cache
echo "-- change build file of one module, with config cache (invalidates the cache)"
echo "// touch" >> "$WORK/platform/notify/build.gradle.kts"
TAIL=6 g build --configuration-cache
echo "-- cold clean build, config cache on, build cache off"
TAIL=6 g clean build --configuration-cache --rerun-tasks
echo; echo "### type-safe accessors (settings had no feature flag): ok if the builds above passed"
echo "### project tree"; TAIL=30 g projects
"$GRADLE" --stop 2>&1 | tail -2
echo "cache size end: $(du -sb "$GRADLE_USER_HOME" | cut -f1) bytes"
