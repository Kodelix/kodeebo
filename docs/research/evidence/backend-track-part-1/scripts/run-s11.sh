#!/usr/bin/env bash
# S11: Ktor 3.6.0 probe build time, dependency locking, verification metadata, reproducibility, install size.
# Command: bash scripts/run-s11.sh > s11-output.txt 2>&1   (from the evidence dir)
source "$(dirname "$0")/lib.sh"
GV=9.7.0
DL=$EVID/downloads/gradle-$GV-dist
export GRADLE_USER_HOME=$EVID/scratch/gradle-home
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$EVID/tmp"
echo "date=$(date -u +%FT%TZ) java=$(java -version 2>&1 | head -1) host_cpus=$(nproc)"
mkdir -p "$DL" "$GRADLE_USER_HOME"
if [ ! -x "$DL/gradle-$GV/bin/gradle" ]; then
  t0=$(now_ms)
  curl -fsSL --max-time 300 -o "$DL/gradle-$GV-bin.zip" "https://services.gradle.org/distributions/gradle-$GV-bin.zip" || { echo GRADLE_DOWNLOAD_FAILED; exit 1; }
  curl -fsSL --max-time 60 -o "$DL/gradle-$GV-bin.zip.sha256" "https://services.gradle.org/distributions/gradle-$GV-bin.zip.sha256"
  echo "gradle_download_ms=$(( $(now_ms) - t0 ))"
  echo "published_sha256=$(cat "$DL/gradle-$GV-bin.zip.sha256")"
  echo "actual_sha256=$(sha256sum "$DL/gradle-$GV-bin.zip" | cut -c1-64)"
  (cd "$DL" && unzip -q "gradle-$GV-bin.zip")
fi
GRADLE=$DL/gradle-$GV/bin/gradle
"$GRADLE" --version --no-daemon 2>&1 | grep -E "^Gradle|Kotlin|JVM|OS:"

rm -rf "$EVID/scratch/s11"; mkdir -p "$EVID/scratch/s11/a" "$EVID/scratch/s11/b"
cp -r "$EVID/scripts/ktor-probe/." "$EVID/scratch/s11/a/"
cp -r "$EVID/scripts/ktor-probe/." "$EVID/scratch/s11/b/"
OPTS="--no-daemon -Pkotlin.compiler.execution.strategy=in-process --console=plain -q"

cd "$EVID/scratch/s11/a"
echo "=== write locks (resolves + downloads) ==="
t0=$(now_ms); "$GRADLE" $OPTS dependencies --write-locks > /dev/null 2> "$EVID/s11-locks-stderr.txt"; echo "write_locks_cold_ms=$(( $(now_ms) - t0 )) exit=$?"
echo "lockfile_lines=$(grep -vc '^#' gradle.lockfile) lockfile_entries_unique=$(grep -v '^#' gradle.lockfile | cut -d= -f1 | sort -u | wc -l)"
cp gradle.lockfile "$EVID/s11-gradle.lockfile"
echo "=== write verification metadata + first build ==="
t0=$(now_ms); "$GRADLE" $OPTS --write-verification-metadata sha256 installDist 2> "$EVID/s11-build-stderr.txt"; rc=$?; echo "verification_metadata_plus_build_cold_ms=$(( $(now_ms) - t0 )) exit=$rc"
[ $rc -ne 0 ] && { echo BUILD_FAILED; head -40 "$EVID/s11-build-stderr.txt"; exit 1; }
cp gradle/verification-metadata.xml "$EVID/s11-verification-metadata.xml"
echo "verification_components=$(grep -c '<component ' gradle/verification-metadata.xml) artifacts=$(grep -c '<artifact ' gradle/verification-metadata.xml)"
echo "=== warm rebuild (clean + installDist, deps cached, no daemon) ==="
t0=$(now_ms); "$GRADLE" $OPTS clean installDist 2>/dev/null; echo "rebuild_warm_no_daemon_ms=$(( $(now_ms) - t0 ))"
echo "install_lib_jars=$(ls build/install/probe-ktor/lib | wc -l) install_lib_bytes=$(du -sb build/install/probe-ktor/lib | cut -f1) app_jar_bytes=$(stat -c %s build/install/probe-ktor/lib/probe-ktor.jar)"
du -b build/install/probe-ktor/lib/*.jar | sort -rn | head -8
echo "=== Ktor 3.6.0 Gradle module metadata: JVM level and Kotlin ==="
grep -rh --include='ktor-server-core-jvm-3.6.0.module' -E 'org.gradle.jvm.version|kotlin.version|"kotlin' "$GRADLE_USER_HOME/caches/modules-2/files-2.1/io.ktor/ktor-server-core-jvm" | sort | uniq -c
for j in ktor-server-core-jvm ktor-server-netty-jvm; do
  f=$(ls "$GRADLE_USER_HOME"/caches/modules-2/files-2.1/io.ktor/$j/3.6.0/*/$j-3.6.0.jar | head -1)
  c=$(unzip -l "$f" | awk '/\.class/{print $4; exit}')
  mkdir -p "$EVID/scratch/s11/cls-$j"; (cd "$EVID/scratch/s11/cls-$j" && unzip -qo "$f" "$c")
  echo "$j first_class=$c class_major=$(od -An -j6 -N2 -tu1 "$EVID/scratch/s11/cls-$j/$c" | awk '{print $1*256+$2}') (52=Java8 55=11 61=17 65=21)"
done

echo "=== reproducibility: default archive settings (a vs b, different dirs) ==="
cd "$EVID/scratch/s11/b" && "$GRADLE" $OPTS --write-verification-metadata sha256 installDist distZip 2>/dev/null
cd "$EVID/scratch/s11/a" && "$GRADLE" $OPTS clean distZip 2>/dev/null
for d in a b; do echo "default $d jar=$(sha256sum $EVID/scratch/s11/$d/build/install/probe-ktor/lib/probe-ktor.jar | cut -c1-16) zip=$(sha256sum $EVID/scratch/s11/$d/build/distributions/probe-ktor.zip | cut -c1-16)"; done
sleep 2
echo "=== reproducibility: -Prepro (no timestamps, reproducible order) ==="
for d in a b; do (cd $EVID/scratch/s11/$d && "$GRADLE" $OPTS -Prepro clean installDist distZip 2>/dev/null); done
for d in a b; do echo "repro $d jar=$(sha256sum $EVID/scratch/s11/$d/build/install/probe-ktor/lib/probe-ktor.jar | cut -c1-16) zip=$(sha256sum $EVID/scratch/s11/$d/build/distributions/probe-ktor.zip | cut -c1-16)"; done
cd "$EVID/scratch/s11/a" && "$GRADLE" $OPTS -Prepro clean installDist 2>/dev/null
mkdir -p "$EVID/scratch/s11/install" && rm -rf "$EVID/scratch/s11/install/probe-ktor" && cp -r build/install/probe-ktor "$EVID/scratch/s11/install/"
echo "done"
