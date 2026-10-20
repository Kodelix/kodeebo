#!/bin/bash
# S51b run 2 (scan step only). Run 1 (s51b-db-scan.sh) downloaded the DB fine but its scans failed: mounting
# the db/ directory onto /tmp/trivycache/db made the parent a root-owned directory in the tmpfs, so Trivy
# (uid 65534) could not create its layer cache there ("mkdir /tmp/trivycache/fanal: permission denied").
# Fix without weakening anything: the WHOLE cache dir is mounted read-only at /cache (TRIVY_CACHE_DIR=/cache)
# and Trivy's layer cache is kept in memory with --cache-backend memory. Container flags otherwise as s51-lib.sh
# (--network none).
set -u
. "$(dirname "$0")/s51-lib.sh"
OUT=$EVID/out; DBC=$CACHE/trivy-cache
WRAP='s=$(date +%s%N); /opt/trivy/trivy "$@"; rc=$?; e=$(date +%s%N); echo "RESULT exit=$rc elapsed_ms=$(( (e-s)/1000000 )) memory.peak_bytes=$(cat /sys/fs/cgroup/memory.peak 2>&1)"; exit $rc'
echo "date_utc: $(date -u +%FT%TZ)"
echo "scan docker flags: ${SCAN_DOCKER_FLAGS[*]} -e TRIVY_CACHE_DIR=/cache -v $DBC:/cache:ro"
NF="--skip-version-check --disable-telemetry --offline-scan --skip-db-update --cache-backend memory"
run() { local name=$1 tar=$2 label=$3; shift 3
  echo; echo "######## [$label] $name :: trivy $*"
  docker run "${SCAN_DOCKER_FLAGS[@]}" -e TRIVY_CACHE_DIR=/cache -v "$DBC":/cache:ro -v "$CACHE/images/$tar":/in/img.tar:ro -v "$OUT":/out:rw \
    --entrypoint /bin/sh "$RUNTIME" -c "$WRAP" sh "$@" 2>&1 | cut -c1-300 | tail -12
}
for pair in "temurin:eclipse-temurin-21-jre.tar" "ktor:kprobe-ktor-latest.tar"; do
  n=${pair%%:*}; t=${pair#*:}
  run $n $t V7-cdx image --input /in/img.tar --format cyclonedx --pkg-types os --scanners vuln --skip-java-db-update $NF -o /out/$n.V7.cdx.json
  run $n $t V7-json image --input /in/img.tar --format json --pkg-types os --scanners vuln --skip-java-db-update $NF -o /out/$n.V7.json
  run $n $t V8-json-java-db-flag-omitted image --input /in/img.tar --format json --pkg-types os --scanners vuln $NF -o /out/$n.V8.json
done
echo; echo "== counts (severity counts and IDs only; no advisory text)"
python3 -I - "$OUT" <<'PY'
import json,sys,collections,os
d=sys.argv[1]
for n in ("temurin","ktor"):
    for v in ("V7","V8"):
        p=f"{d}/{n}.{v}.json"
        if not os.path.exists(p): print(n,v,"no file"); continue
        r=json.load(open(p)); c=collections.Counter(); ids=set(); fixed=0; tot=0
        for res in r.get("Results",[]):
            for x in res.get("Vulnerabilities",[]) or []:
                c[x.get("Severity")]+=1; ids.add(x.get("VulnerabilityID")); tot+=1
                if x.get("FixedVersion"): fixed+=1
        print(n,v,"findings",tot,"unique ids",len(ids),"with fixed version",fixed,dict(c),"ArtifactType",r.get("ArtifactType"),"OS",r.get("Metadata",{}).get("OS"),"results",[(x.get("Target"),x.get("Class")) for x in r.get("Results",[])][:4])
    p=f"{d}/{n}.V7.cdx.json"
    if os.path.exists(p):
        m=json.load(open(p)); vs=m.get("vulnerabilities",[]); sv=collections.Counter()
        for x in vs:
            for rt in x.get("ratings",[]): sv[rt.get("severity")]+=1
        print(n,"V7 cdx specVersion",m.get("specVersion"),"components",len(m.get("components",[])),"vulnerabilities",len(vs),"rating severities",dict(sv),"bytes",os.path.getsize(p))
PY
echo "-- cache dir contents after the scans (must be unchanged: db only)"; ls -la "$DBC"; ls "$DBC/db"
