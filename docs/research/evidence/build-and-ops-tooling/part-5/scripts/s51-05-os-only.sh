#!/bin/bash
# S51 step 5: variants that avoid the Java DB: OS-package-only SBOM, vulnerability scanner without a DB,
# and skipping JAR files. Same locked-down container as s51-lib.sh, no network.
set -u
. "$(dirname "$0")/s51-lib.sh"
OUT=$EVID/out; mkdir -p "$OUT"; chmod 0777 "$OUT"
WRAP='s=$(date +%s%N); /opt/trivy/trivy "$@"; rc=$?; e=$(date +%s%N); echo "RESULT exit=$rc elapsed_ms=$(( (e-s)/1000000 )) memory.peak_bytes=$(cat /sys/fs/cgroup/memory.peak 2>&1)"; exit $rc'
echo "date_utc: $(date -u +%FT%TZ)"
run() { local name=$1 tar=$2 label=$3; shift 3
  echo; echo "######## [$label] $name :: trivy $*"
  docker run "${SCAN_DOCKER_FLAGS[@]}" -v "$CACHE/images/$tar":/in/img.tar:ro -v "$OUT":/out:rw \
    --entrypoint /bin/sh "$RUNTIME" -c "$WRAP" sh "$@" 2>&1 | cut -c1-420 | tail -12
}
NF="--skip-version-check --disable-telemetry --offline-scan --skip-db-update --skip-java-db-update"
for pair in "temurin:eclipse-temurin-21-jre.tar" "ktor:kprobe-ktor-latest.tar"; do
  n=${pair%%:*}; t=${pair#*:}
  run $n $t V4-os-packages-only-cyclonedx image --input /in/img.tar --format cyclonedx --pkg-types os --scanners license $NF -o /out/$n.V4.cdx.json
  run $n $t V5-vuln-scanner-no-db image --input /in/img.tar --format json --pkg-types os --scanners vuln $NF -o /out/$n.V5.json
  run $n $t V6-skip-jar-files image --input /in/img.tar --format cyclonedx --scanners license --skip-files "**/*.jar" $NF -o /out/$n.V6.cdx.json
done
ls -l "$OUT"
