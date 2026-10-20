#!/bin/bash
# S51b: (a) update step: ONLY ghcr.io/aquasecurity/trivy-db:2 into the cache dir, in the locked-down container
# with network enabled for this step only (default bridge; every other flag as in s51-lib.sh);
# (b) scan step: --network none, DB mounted READ-ONLY (only the db/ directory, onto a tmpfs cache dir so
# Trivy's own layer cache lands in tmpfs), image tarball read-only, OS packages only, vulnerability scanner.
# Guard: abort if the current trivy-db layer differs by more than 10 percent from 135,378,999 bytes.
set -u
. "$(dirname "$0")/s51-lib.sh"
OUT=$EVID/out; mkdir -p "$OUT"; chmod 0777 "$OUT"
DBC=$CACHE/trivy-cache; mkdir -p "$DBC"
[ -z "$(ls -A "$DBC")" ] || { echo "cache dir not empty: $DBC"; exit 1; }
chmod 0777 "$DBC"
WRAP='s=$(date +%s%N); /opt/trivy/trivy "$@"; rc=$?; e=$(date +%s%N); echo "RESULT exit=$rc elapsed_ms=$(( (e-s)/1000000 )) memory.peak_bytes=$(cat /sys/fs/cgroup/memory.peak 2>&1)"; exit $rc'
echo "date_utc: $(date -u +%FT%TZ)"
echo "== size guard: current manifest of ghcr.io/aquasecurity/trivy-db:2"
TOK=$(curl -fsS --max-time 30 "https://ghcr.io/token?service=ghcr.io&scope=repository:aquasecurity/trivy-db:pull" | python3 -I -c 'import json,sys;print(json.load(sys.stdin)["token"])') || { echo token failed; exit 1; }
curl -fsS --max-time 30 -D "$EVID/manifests/s51b.trivy-db.2.headers" -H "Authorization: Bearer $TOK" -H "Accept: application/vnd.oci.image.manifest.v1+json" https://ghcr.io/v2/aquasecurity/trivy-db/manifests/2 -o "$EVID/manifests/s51b.trivy-db.2.json" || { echo manifest failed; exit 1; }
grep -i docker-content-digest "$EVID/manifests/s51b.trivy-db.2.headers" | tr -d '\r'
python3 -I - "$EVID/manifests/s51b.trivy-db.2.json" <<'PY' || { echo "SIZE GUARD FAILED - not downloading"; exit 1; }
import json,sys
m=json.load(open(sys.argv[1])); l=m["layers"][0]; s=l["size"]
print("layer digest",l["digest"],"size",s,"created",m.get("annotations",{}).get("org.opencontainers.image.created"))
sys.exit(0 if abs(s-135378999)/135378999<=0.10 else 1)
PY
echo "== (a) UPDATE STEP (network on, default bridge; all other flags unchanged)"
UPD=(); skip=0
for x in "${SCAN_DOCKER_FLAGS[@]}"; do
  if [ $skip = 1 ]; then skip=0; continue; fi
  if [ "$x" = "--network" ]; then skip=1; continue; fi
  UPD+=("$x")
done
echo "update docker flags: ${UPD[*]} -e TRIVY_CACHE_DIR=/cache -v $DBC:/cache:rw"
docker run "${UPD[@]}" -e TRIVY_CACHE_DIR=/cache -v "$DBC":/cache:rw --entrypoint /bin/sh "$RUNTIME" -c "$WRAP" sh \
  image --download-db-only --db-repository ghcr.io/aquasecurity/trivy-db:2 --skip-version-check --disable-telemetry 2>&1 | cut -c1-300 | tail -15
echo "-- cache tree"; find "$DBC" -maxdepth 3 -printf '%p %s bytes\n' | head -20; du -sh "$DBC"
echo "-- db/metadata.json"; cat "$DBC/db/metadata.json" 2>&1
[ -f "$DBC/db/trivy.db" ] || { echo "no DB - stop"; exit 1; }
echo; echo "== (b) SCAN STEP (--network none; db/ mounted read-only onto the tmpfs cache dir)"
echo "scan docker flags: ${SCAN_DOCKER_FLAGS[*]} -v $DBC/db:/tmp/trivycache/db:ro"
NF="--skip-version-check --disable-telemetry --offline-scan --skip-db-update"
run() { local name=$1 tar=$2 label=$3; shift 3
  echo; echo "######## [$label] $name :: trivy $*"
  docker run "${SCAN_DOCKER_FLAGS[@]}" -v "$DBC/db":/tmp/trivycache/db:ro -v "$CACHE/images/$tar":/in/img.tar:ro -v "$OUT":/out:rw \
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
echo "-- java db present in cache?"; ls "$DBC"; ls -la "$OUT" | head -30
