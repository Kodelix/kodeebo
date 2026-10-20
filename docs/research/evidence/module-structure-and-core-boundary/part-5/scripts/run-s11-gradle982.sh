#!/usr/bin/env bash
# PART 5 ADAPTATION of part-1 scripts/run-sNN.sh: ONLY the Gradle distribution (9.8.2), GRADLE_USER_HOME (part-5 home-a, copy of part-1 home) and evidence/cache paths changed.
# S11 - dependency locking and strict verification across modules and an included build (tier E).
# Usage: bash scripts/run-s11.sh > s11-run2-output.txt   (offline only; Gradle 9.7.0 from part 2's cache, read-only)
# Run 1 (s11-run1-output.txt) = WRONG RUN: resolveAndLockAll needed an artifact absent from the offline cache; coroutines 1.11.0 also absent.
set -u
REPO=/home/kiko/saas-products/kodeebo
EV=$REPO/docs/research/evidence/module-structure-and-core-boundary/part-5/probes/part-1
CACHE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-5
GRADLE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-5/gradle-dist/gradle-9.8.2/bin/gradle
export GRADLE_USER_HOME=$CACHE/home-a
WORK=$CACHE/work-s11
rm -rf "$WORK"; mkdir -p "$WORK"; cp -r "$EV/s10/project/." "$WORK/"
cp "$EV/s11/overlay/build.gradle.kts" "$WORK/build.gradle.kts"; cp "$EV/s11/overlay/build-logic/build.gradle.kts" "$WORK/build-logic/build.gradle.kts"
echo "date: $(date -u +%FT%TZ)"
g() { echo; echo "### gradle $*"; local s=$(date +%s%N); "$GRADLE" -p "$WORK" --offline --console=plain "$@" 2>&1 | tail -n ${TAIL:-30}; echo "exit=${PIPESTATUS[0]} wall_ms=$(( ($(date +%s%N) - s) / 1000000 ))"; }
lf() { (cd "$WORK" && find . -name '*lockfile' -not -path '*/build/*' | sort | while read f; do echo "$f $(grep -vc '^#' "$f") entries"; done); }
echo "######## 1: 'dependencies --write-locks' on the root only"
TAIL=6 g dependencies --write-locks; lf
find "$WORK" -name '*lockfile' -not -path '*/build/*' -delete
echo; echo "######## 1c: resolveAndLockAll (every resolvable configuration, incl. Kotlin tooling) --write-locks, offline"
TAIL=14 g resolveAndLockAll --write-locks; lf
find "$WORK" -name '*lockfile' -not -path '*/build/*' -delete
echo; echo "######## 2: assemble testClasses updateKotlinAbi --write-locks (what the build really resolves)"
TAIL=6 g assemble testClasses updateKotlinAbi --write-locks; lf
echo "-- head of root buildscript-gradle.lockfile and notify gradle.lockfile"; head -8 "$WORK/buildscript-gradle.lockfile"; head -12 "$WORK/platform/notify/gradle.lockfile"
echo "-- is 2.4.0 (kotlin-dsl compiler) in build-logic lock?"; grep -c "kotlin-compiler-embeddable:2.4.0" "$WORK/build-logic/buildscript-gradle.lockfile" "$WORK/build-logic/gradle.lockfile" 2>&1
TAIL=8 g build
echo; echo "######## 3: new dependency not in the lock (kotlin-reflect 2.4.0, present in the offline cache, added to notify)"
sed -i 's|implementation(projects.platform.ratelimit)|implementation(projects.platform.ratelimit)\n    implementation("org.jetbrains.kotlin:kotlin-reflect:2.4.0")|' "$WORK/platform/notify/build.gradle.kts"
TAIL=22 g :platform:notify:compileKotlin
TAIL=6 g :platform:notify:dependencies --write-locks --configuration compileClasspath
TAIL=6 g :platform:notify:compileKotlin
echo; echo "######## 4: verification metadata (written across all projects and the included build)"
TAIL=8 g --write-verification-metadata sha256 build
V=$WORK/gradle/verification-metadata.xml; ls -la "$V"; echo "components: $(grep -c '<component ' "$V")  artifacts: $(grep -c '<artifact ' "$V")"
echo "kotlin-compiler-embeddable versions listed:"; grep -o 'name="kotlin-compiler-embeddable" version="[^"]*"' "$V" | sort -u
echo "kotlin-gradle-plugin versions listed:"; grep -o 'name="kotlin-gradle-plugin" version="[^"]*"' "$V" | sort -u
echo "build-logic jar / project artifacts listed?"; grep -c 'build-logic' "$V"
TAIL=6 g build
echo; echo "######## 5: tamper a checksum of a project dependency (kotlin-stdlib 2.4.21 jar)"
cp "$V" "$V.orig"
python3 -I - "$V" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
m=re.search(r'(<artifact name="kotlin-stdlib-2\.4\.21\.jar">\s*<sha256 value=")([0-9a-f]{64})',s)
print("tampering", m.group(2)[:12]); s=s[:m.start(2)]+"0"*64+s[m.end(2):]; open(p,'w').write(s)
PY
TAIL=22 g build
cp "$V.orig" "$V"
echo; echo "######## 6: tamper a checksum of a build-logic dependency (kotlin-gradle-plugin 2.4.21 jar)"
python3 -I - "$V" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
m=re.search(r'(<artifact name="kotlin-gradle-plugin-2\.4\.21\.jar">\s*<sha256 value=")([0-9a-f]{64})',s)
print("tampering", m.group(2)[:12]); s=s[:m.start(2)]+"0"*64+s[m.end(2):]; open(p,'w').write(s)
PY
TAIL=22 g build
cp "$V.orig" "$V"
echo; echo "######## 7: jar changed IN THE DEPENDENCY CACHE (one byte appended), metadata intact, offline"
J=$(find "$GRADLE_USER_HOME/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib/2.4.21" -name 'kotlin-stdlib-2.4.21.jar')
cp -p "$J" "$J.bak-s11"; printf 'X' >> "$J"
TAIL=22 g build --rerun-tasks
mv "$J.bak-s11" "$J"
TAIL=6 g build
"$GRADLE" --stop 2>&1 | tail -1
