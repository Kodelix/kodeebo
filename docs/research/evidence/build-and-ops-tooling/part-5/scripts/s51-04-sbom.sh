#!/bin/bash
# S51 step 4: what Trivy v0.76.0 does with NO database and NO network, on two docker-save tarballs,
# under the founder's scanner condition (see s51-lib.sh). Wall time and cgroup peak memory are
# read INSIDE the container (date +%s%N around the run; /sys/fs/cgroup/memory.peak, cgroup v2).
set -u
. "$(dirname "$0")/s51-lib.sh"
OUT=$EVID/out; mkdir -p "$OUT"; chmod 0777 "$OUT"
WRAP='s=$(date +%s%N); /opt/trivy/trivy "$@"; rc=$?; e=$(date +%s%N); echo "RESULT exit=$rc elapsed_ms=$(( (e-s)/1000000 )) memory.peak_bytes=$(cat /sys/fs/cgroup/memory.peak 2>&1)"; exit $rc'
echo "date_utc: $(date -u +%FT%TZ)"
echo "docker flags: ${SCAN_DOCKER_FLAGS[*]}"
run() { # name image-tar-basename label -- trivy args...
  local name=$1 tar=$2 label=$3; shift 3
  echo; echo "######## [$label] $name :: trivy $*"
  docker run "${SCAN_DOCKER_FLAGS[@]}" -v "$CACHE/images/$tar":/in/img.tar:ro -v "$OUT":/out:rw \
    --entrypoint /bin/sh "$RUNTIME" -c "$WRAP" sh "$@" 2>&1 | cut -c1-400 | tail -${TAILN:-25}
}
NF="--skip-version-check --disable-telemetry --offline-scan --skip-db-update --skip-java-db-update"
for pair in "temurin:eclipse-temurin-21-jre.tar" "ktor:kprobe-ktor-latest.tar"; do
  n=${pair%%:*}; t=${pair#*:}
  # V2: licence scanner only (no vulnerability scanner), CycloneDX: expected to need no DB
  run $n $t V2-license-only image --input /in/img.tar --format cyclonedx --scanners license $NF -o /out/$n.V2.cdx.json
  # V1: default scanners (vuln,secret), CycloneDX, DB skipped: expected to fail for lack of a DB
  run $n $t V1-default-scanners image --input /in/img.tar --format cyclonedx $NF -o /out/$n.V1.cdx.json
  # V3: licence only, WITHOUT --skip-java-db-update and --offline-scan: what does it try to fetch for JARs?
  run $n $t V3-java-db-not-skipped image --input /in/img.tar --format cyclonedx --scanners license --skip-version-check --disable-telemetry --skip-db-update -o /out/$n.V3.cdx.json
done
ls -l "$OUT"
