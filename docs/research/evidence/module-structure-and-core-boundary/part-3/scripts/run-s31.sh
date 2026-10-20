#!/usr/bin/env bash
# S31 (tier E, throwaway): lift of two Gradle modules (tenancy, audit) out of a product build into a separate "core" build,
# published with maven-publish to a FILE repository and consumed (a) by coordinates from that repository, (b) by coordinates
# through an included build (composite). Checks: callers' Kotlin source unchanged, ABI dump moves intact, locks, strict
# verification, published-artifact reproducibility and tamper. Gradle 9.7.0, Kotlin 2.4.21, OFFLINE, --no-daemon.
# Usage: bash run-s31.sh > s31-output.txt     (the Gradle user home copy is made on the first run only)
set -u
REPO=/home/kiko/saas-products/kodeebo
EV=$REPO/docs/research/evidence/module-structure-and-core-boundary
C1=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-1
CACHE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-3
GRADLE=$REPO/production/session-state/cache/module-structure-and-core-boundary/part-2/gradle-9.7.0/bin/gradle
export GRADLE_USER_HOME=$CACHE/home
[ -d "$GRADLE_USER_HOME" ] || cp -r "$C1/home" "$GRADLE_USER_HOME"
BASE=$CACHE/work-s31; PROD=$BASE/product; CORE=$BASE/core; M2=$BASE/m2repo
rm -rf "$BASE"; mkdir -p "$PROD" "$CORE" "$M2"
cp -r "$EV/part-1/s10/project/." "$PROD/"
cp "$EV/part-1/s11/overlay/build.gradle.kts" "$PROD/build.gradle.kts"; cp "$EV/part-1/s11/overlay/build-logic/build.gradle.kts" "$PROD/build-logic/build.gradle.kts"
g() { local d=$1; shift; echo; echo "### [$(basename $d)] gradle $*"; local s=$(date +%s%N); "$GRADLE" -p "$d" --offline --no-daemon --console=plain "$@" 2>&1 | grep -v '^> Task\|^$\|Run with\|^> Get more\|^\* Try\|^Daemon will\|^Starting a Gradle\|^Configuration cache' | tail -n ${TAIL:-12}; echo "exit=${PIPESTATUS[0]} wall_ms=$(( ($(date +%s%N) - s) / 1000000 ))"; }
V=$PROD/gradle/verification-metadata.xml
echo "date: $(date -u +%FT%TZ)"; "$GRADLE" --version --offline --no-daemon 2>&1 | grep -E "^Gradle|^Kotlin|^JVM"

echo; echo "######## P1: product BEFORE the lift (project dependencies): locks, ABI dumps, verification metadata, build"
TAIL=3 g $PROD assemble testClasses updateKotlinAbi --write-locks
TAIL=3 g $PROD --write-verification-metadata sha256 build
TAIL=4 g $PROD build
echo "verification components before: $(grep -c '<component ' $V)"
cp $V $BASE/verification-before.xml
echo "--- build files that mention the two modules (before):"; grep -rn "platform.audit\|platform.tenancy\|:platform:audit\|:platform:tenancy" $PROD --include=*.kts | grep -v "/build/\|/.gradle/"
( cd $PROD && find app platform/notify platform/ratelimit contexts -path '*/src/*' -type f | sort | xargs sha256sum ) > $BASE/callers-src-before.sha
( cd $PROD/platform && sha256sum tenancy/api/*.api audit/api/*.api ) > $BASE/abi-before.sha
cat $BASE/abi-before.sha; wc -l $BASE/callers-src-before.sha

echo; echo "######## L1: LIFT = move the two module directories into a separate build (core) with its own settings, build-logic and publishing"
mv $PROD/platform/tenancy $CORE/tenancy; mv $PROD/platform/audit $CORE/audit
cp -r $PROD/build-logic $CORE/build-logic; rm -rf $CORE/build-logic/build $CORE/build-logic/.gradle $CORE/build-logic/.kotlin
cp $PROD/gradle.properties $CORE/gradle.properties
cat > $CORE/settings.gradle.kts <<'EOF'
pluginManagement { includeBuild("build-logic") }
dependencyResolutionManagement { repositories { mavenCentral() } }
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")
rootProject.name = "saas-core-probe"
include(":tenancy", ":audit")
EOF
cat > $CORE/build.gradle.kts <<'EOF'
buildscript { configurations.classpath { resolutionStrategy.activateDependencyLocking() } }
EOF
cat > $CORE/build-logic/src/main/kotlin/kodeebo.kotlin-module.gradle.kts <<'EOF'
// Core copy of the convention plugin: product version + maven-publish to a file repository.
plugins {
    id("org.jetbrains.kotlin.jvm")
    `java-library`
    `maven-publish`
}
group = "net.kodelix.core"
version = "0.1.0"
kotlin {
    jvmToolchain(21)
    explicitApi()
    @OptIn(org.jetbrains.kotlin.gradle.dsl.abi.ExperimentalAbiValidation::class)
    abiValidation()
}
dependencyLocking { lockAllConfigurations() }
publishing {
    publications { create<MavenPublication>("maven") { from(components["java"]) } }
    repositories { maven { name = "file"; url = uri(providers.gradleProperty("publishRepo").getOrElse(layout.buildDirectory.dir("m2").get().asFile.path)) } }
}
if (providers.gradleProperty("reproducible").isPresent) {
    tasks.withType<AbstractArchiveTask>().configureEach { isPreserveFileTimestamps = false; isReproducibleFileOrder = true }
}
EOF
# the lifted module's own build file: only the project-path notation inside the core changes
sed -i 's/projects\.platform\.tenancy/projects.tenancy/' $CORE/audit/build.gradle.kts
echo "--- core/audit/build.gradle.kts after the move:"; cat $CORE/audit/build.gradle.kts
( cd $CORE && sha256sum tenancy/api/*.api audit/api/*.api ) | sed 's#  \(tenancy\|audit\)/#  \1/#' > $BASE/abi-after-core.sha
echo "--- ABI dump identical after the move? (diff of sha lists, paths normalised)"; diff <(sed 's#platform/##' $BASE/abi-before.sha) $BASE/abi-after-core.sha && echo "IDENTICAL"
echo; echo "######## C1: core build: locks, checkKotlinAbi with the MOVED dump (no updateKotlinAbi), build"
TAIL=3 g $CORE assemble testClasses --write-locks
TAIL=6 g $CORE checkKotlinAbi
echo; echo "######## C2: publish to the file repository, twice, default jars (timestamps) vs -Preproducible"
TAIL=4 g $CORE publish -PpublishRepo=$M2
echo "--- published files:"; ( cd $M2 && find . -type f | sort )
JAR=$M2/net/kodelix/core/audit/0.1.0/audit-0.1.0.jar
sha256sum $JAR | tee $BASE/jar-run1.sha
sleep 2; TAIL=3 g $CORE clean publish -PpublishRepo=$M2
sha256sum $JAR | tee $BASE/jar-run2.sha
echo "default jars identical across two publishes? $(cmp -s <(cut -d' ' -f1 $BASE/jar-run1.sha) <(cut -d' ' -f1 $BASE/jar-run2.sha) && echo YES || echo NO)"
TAIL=3 g $CORE clean publish -PpublishRepo=$M2 -Preproducible=true; sha256sum $JAR | tee $BASE/jar-run3.sha
sleep 2; TAIL=3 g $CORE clean publish -PpublishRepo=$M2 -Preproducible=true; sha256sum $JAR | tee $BASE/jar-run4.sha
echo "reproducible jars identical across two publishes? $(cmp -s <(cut -d' ' -f1 $BASE/jar-run3.sha) <(cut -d' ' -f1 $BASE/jar-run4.sha) && echo YES || echo NO)"
echo "--- audit POM:"; cat $M2/net/kodelix/core/audit/0.1.0/audit-0.1.0.pom
echo "--- audit .module (dependencies part):"; grep -n '"group"\|"module"\|"version"\|"name": "\(api\|runtime\)Elements"' $M2/net/kodelix/core/audit/0.1.0/audit-0.1.0.module | head -20

echo; echo "######## A: product AFTER the lift, consuming by COORDINATES from the file repository"
sed -i 's/, ":platform:tenancy", ":platform:audit"//; s/":platform:tenancy", ":platform:audit", //' $PROD/settings.gradle.kts
sed -i 's#repositories { mavenCentral() }#repositories { maven { url = uri("'$M2'"); content { includeGroup("net.kodelix.core") } }; mavenCentral() }#' $PROD/settings.gradle.kts
grep -rl "projects.platform.audit\|projects.platform.tenancy" $PROD --include=build.gradle.kts | grep -v /build-logic/ | while read f; do sed -i 's/projects\.platform\.audit/"net.kodelix.core:audit:0.1.0"/; s/projects\.platform\.tenancy/"net.kodelix.core:tenancy:0.1.0"/' $f; done
echo "--- product settings.gradle.kts:"; cat $PROD/settings.gradle.kts
echo "--- product build files that mention the core modules (after):"; grep -rn "net.kodelix.core\|platform.audit\|platform.tenancy" $PROD --include=*.kts | grep -v "/build/\|/.gradle/"
( cd $PROD && find app platform/notify platform/ratelimit contexts -path '*/src/*' -type f | sort | xargs sha256sum ) > $BASE/callers-src-after.sha
echo "callers' Kotlin source files identical before/after the lift? $(cmp -s $BASE/callers-src-before.sha $BASE/callers-src-after.sha && echo YES-byte-identical || echo NO)"
echo; echo "--- A1: build with the OLD locks and OLD verification metadata (expect failure)"
TAIL=8 g $PROD build
echo "--- A2: re-lock, then rewrite verification metadata"
# run 2 fix: old metadata blocks the lock write, stale locks block the metadata write -> lock with verification off, then write metadata
TAIL=3 g $PROD assemble testClasses updateKotlinAbi --write-locks --dependency-verification off
TAIL=5 g $PROD --write-verification-metadata sha256 build
echo "verification components after: $(grep -c '<component ' $V)  (before: $(grep -c '<component ' $BASE/verification-before.xml))"
echo "--- entries for net.kodelix.core in verification metadata:"; grep -n -A4 'group="net.kodelix.core"' $V | head -40
echo "--- app lockfile lines for net.kodelix:"; grep -n "net.kodelix" $PROD/app/gradle.lockfile $PROD/platform/*/gradle.lockfile 2>/dev/null | head
echo "--- A3: control build strict"; TAIL=4 g $PROD build
cp $V $BASE/verification-A.xml
echo "--- A4: tamper the published jar in the file repository (append one byte), build --rerun-tasks"
cp $JAR $BASE/audit-0.1.0.jar.orig; printf 'x' >> $JAR
TAIL=10 g $PROD build --rerun-tasks
cp $BASE/audit-0.1.0.jar.orig $JAR
echo "--- A5: tamper the checksum of the published audit jar in verification-metadata.xml"
python3 -I - "$V" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
m=re.search(r'(<artifact name="audit-0\.1\.0\.jar">\s*<sha256 value=")([0-9a-f]{64})',s)
print("tampering" if m else "NO MATCH");
if m: open(p,'w').write(s[:m.start(2)]+"0"*64+s[m.end(2):])
PY
TAIL=10 g $PROD build; cp $BASE/verification-A.xml $V
echo "--- A6: control after restore"; TAIL=4 g $PROD build

echo; echo "######## B: product consuming the SAME coordinates through an INCLUDED BUILD (composite), repository entry kept but jar tamper-free"
sed -i 's#^rootProject.name#includeBuild("../core")\nrootProject.name#' $PROD/settings.gradle.kts
echo "--- product settings.gradle.kts:"; cat $PROD/settings.gradle.kts
echo "--- B1: build with the locks and verification metadata of step A (unchanged)"
TAIL=10 g $PROD build
echo "--- B2: where do the core modules come from? (app runtimeClasspath)"
TAIL=40 g $PROD :app:dependencies --configuration runtimeClasspath 2>&1 | grep -n "audit\|tenancy"
echo "--- B3: re-lock and re-write verification metadata with the included build"
TAIL=4 g $PROD assemble testClasses updateKotlinAbi --write-locks
TAIL=5 g $PROD --write-verification-metadata sha256 build
echo "verification components with included build: $(grep -c '<component ' $V)"; diff <(grep -o 'group="[^"]*" name="[^"]*" version="[^"]*"' $BASE/verification-A.xml | sort) <(grep -o 'group="[^"]*" name="[^"]*" version="[^"]*"' $V | sort) && echo "component list unchanged vs step A"
echo "--- app lockfile lines for net.kodelix (included build):"; grep -n "net.kodelix" $PROD/app/gradle.lockfile 2>/dev/null | head
echo "--- B4: tamper a core build-logic dependency checksum in the PRODUCT's file (kotlin-gradle-plugin) -> does the included core build fail?"
cp $V $BASE/verification-B.xml
python3 -I - "$V" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
m=re.search(r'(<artifact name="kotlin-gradle-plugin-2\.4\.21[^"]*\.jar">\s*<sha256 value=")([0-9a-f]{64})',s)
print("tampering" if m else "NO MATCH")
if m: open(p,'w').write(s[:m.start(2)]+"0"*64+s[m.end(2):])
PY
TAIL=8 g $PROD build; cp $BASE/verification-B.xml $V
echo "--- B5: control"; TAIL=4 g $PROD build
echo; echo "######## D: summary diff of the product tree between before and after the lift (build files only?)"
echo "callers' Kotlin source identical: $(cmp -s $BASE/callers-src-before.sha $BASE/callers-src-after.sha && echo YES || echo NO)"
echo DONE
