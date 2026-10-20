#!/usr/bin/env bash
# PART 5 ADAPTATION of part-1 scripts/run-sNN.sh: ONLY the Gradle distribution (9.8.2), GRADLE_USER_HOME (part-5 home-a, copy of part-1 home) and evidence/cache paths changed.
# S12 - completes S11: verification metadata across modules + included build, strict mode, tamper tests with controls (tier E).
# Usage: bash scripts/run-s12.sh > s12-output.txt  (offline; Gradle 9.7.0 from part 2's cache, read-only)
set -u
REPO=/home/kiko/saas-products/kodeebo
EV=$REPO/docs/research/evidence/module-structure-and-core-boundary/part-5/probes/part-1
CACHE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-5
GRADLE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-5/gradle-dist/gradle-9.8.2/bin/gradle
export GRADLE_USER_HOME=$CACHE/home-a
WORK=$CACHE/work-s12
rm -rf "$WORK"; mkdir -p "$WORK"; cp -r "$EV/s10/project/." "$WORK/"
cp "$EV/s11/overlay/build.gradle.kts" "$WORK/build.gradle.kts"; cp "$EV/s11/overlay/build-logic/build.gradle.kts" "$WORK/build-logic/build.gradle.kts"
V=$WORK/gradle/verification-metadata.xml
echo "date: $(date -u +%FT%TZ)"
g() { echo; echo "### gradle $*"; local s=$(date +%s%N); "$GRADLE" -p "$WORK" --offline --console=plain "$@" 2>&1 | grep -v '^> Task\|^$\|Run with\|^> Get more\|^\* Try' | tail -n ${TAIL:-14}; echo "exit=${PIPESTATUS[0]} wall_ms=$(( ($(date +%s%N) - s) / 1000000 ))"; }
tamper() { python3 -I - "$V" "$1" <<'PY'
import re,sys
p,pat=sys.argv[1],sys.argv[2]; s=open(p).read()
m=re.search(r'(<artifact name="'+pat+r'">\s*<sha256 value=")([0-9a-f]{64})',s)
if not m: print("NO MATCH for",pat); sys.exit(0)
print("tampering",pat,m.group(2)[:12]); open(p,'w').write(s[:m.start(2)]+"0"*64+s[m.end(2):])
PY
}
echo "######## 1: locks for all modules, then ABI dumps"
TAIL=3 g assemble testClasses updateKotlinAbi --write-locks
echo; echo "######## 2: write verification metadata (sha256) on build"
TAIL=6 g --write-verification-metadata sha256 build
echo "components: $(grep -c '<component ' "$V")  artifacts: $(grep -c '<artifact ' "$V")  bytes: $(wc -c < "$V")"
grep -o 'name="kotlin-gradle-plugin" version="[^"]*"' "$V" | sort -u; grep -o 'name="gradle-kotlin-dsl-plugins" version="[^"]*"' "$V" | sort -u; grep -c 'kotlin-reflect' "$V"
cp "$V" "$V.orig"
echo; echo "######## 3: control - strict build with intact metadata"
TAIL=5 g build
echo; echo "######## 3b: cost of verification on a full rebuild (verification strict vs off)"
TAIL=3 g clean build --rerun-tasks --dependency-verification strict
TAIL=3 g clean build --rerun-tasks --dependency-verification off
echo; echo "######## 4: tamper checksum of a module dependency (kotlin-stdlib 2.4.21)"
tamper 'kotlin-stdlib-2\.4\.21\.jar'; TAIL=10 g build; cp "$V.orig" "$V"
echo; echo "######## 5: tamper checksum of a build-logic dependency (kotlin-gradle-plugin 2.4.21)"
tamper 'kotlin-gradle-plugin-2\.4\.21[^"]*\.jar'; TAIL=12 g build; cp "$V.orig" "$V"
echo; echo "######## 6: tamper checksum of the kotlin-dsl plugin jar (build-logic buildscript classpath)"
tamper 'gradle-kotlin-dsl-plugins-6\.7\.3\.jar'; TAIL=12 g build; cp "$V.orig" "$V"
echo; echo "######## 7: a component missing from the metadata (annotations 13.0 removed)"
python3 -I - "$V" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
n=re.subn(r'\s*<component group="org.jetbrains" name="annotations" version="13.0">.*?</component>','',s,flags=re.S)
print("removed components:",n[1]); open(p,'w').write(n[0])
PY
TAIL=10 g build; cp "$V.orig" "$V"
echo; echo "######## 8: control after restore, then a cached jar changed on disk (offline, metadata intact)"
TAIL=3 g build
J=$(find "$GRADLE_USER_HOME/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib/2.4.21" -name 'kotlin-stdlib-2.4.21.jar')
cp -p "$J" "$J.bak-s12"; printf 'X' >> "$J"
TAIL=8 g build
TAIL=8 g build --rerun-tasks
mv "$J.bak-s12" "$J"
TAIL=3 g build
cp "$V" "$EV/s11/verification-metadata.s12-COMPLETE.xml"
"$GRADLE" --stop 2>&1 | tail -1
