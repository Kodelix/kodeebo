#!/usr/bin/env bash
# S54 (tier E, part 5, founder decision 2026-10-20: target Gradle 9.8.2, total download cap 280 MB):
# (1) re-list the 9.8.2 distribution size and the published SHA-256; (2) abort if size + 104,287,105 B (kotlin-dsl Kotlin 2.4.10 estimate, F511) > 280,000,000;
# (3) download, verify SHA-256, unpack into an empty dir; (4) record which Kotlin / kotlin-dsl-plugins the distribution carries; (5) make two Gradle user homes as COPIES (home-a from part 1, home-b from part 2).
set -u
REPO=/home/kiko/saas-products/kodeebo
C=$REPO/production/session-state/cache/module-structure-and-core-boundary; D=$C/part-5; mkdir -p $D/dist
echo "date: $(date -u +%FT%TZ)"
URL=https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
size=$(curl -sIL "$URL" | awk 'tolower($1)=="content-length:" {l=$2} END {gsub("\r","",l); print l}')
pub=$(curl -sL $URL.sha256); json=$(curl -sL https://services.gradle.org/versions/current | grep -E '"version"|"checksum"|"buildTime"' | tr -d '\n ')
echo "size: $size bytes"; echo "published sha256 (.sha256 file): $pub"; echo "versions/current: $json"
total=$((size+104287105)); echo "estimated total with kotlin-dsl gap: $total (cap 280000000)"
[ "$total" -gt 280000000 ] && { echo "ABORT: needs approval"; exit 3; }
cd $D/dist && curl -sL -o gradle-9.8.2-bin.zip "$URL"; ls -l gradle-9.8.2-bin.zip
echo "$pub  gradle-9.8.2-bin.zip" | sha256sum -c -
mkdir -p $D/gradle-dist && unzip -q gradle-9.8.2-bin.zip -d $D/gradle-dist
G=$D/gradle-dist/gradle-9.8.2
echo "## distribution lib: kotlin jars and kotlin-dsl plugins"; ls $G/lib | grep -i kotlin | head -20; ls $G/lib/plugins | grep -i -E "kotlin-dsl|kotlin-compiler|kotlin-stdlib" | head
export GRADLE_USER_HOME=$D/home-scratch; mkdir -p $GRADLE_USER_HOME
echo "## gradle --version"; $G/bin/gradle --version --offline --no-daemon 2>&1 | grep -E "^Gradle|^Kotlin|^JVM|^Launcher"; rm -rf $D/home-scratch
echo "## homes (copies)"
cp -r --reflink=auto $C/part-1/home $D/home-a; cp -r --reflink=auto $C/part-2/home $D/home-b; rm -rf $D/home-a/daemon $D/home-b/daemon
du -sh $D/home-a $D/home-b $D/dist $D/gradle-dist
