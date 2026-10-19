#!/usr/bin/env bash
# S14: positive controls for S13, and the pinned scanners (govulncheck 1.8.0, osv-scanner 2.6.0) on the two probes.
# Command: bash scripts/run-s14.sh > s14-output.txt 2>&1   (from the evidence dir)
source "$(dirname "$0")/lib.sh"
export GOTOOLCHAIN=local GOBIN=$EVID/scratch/bin GOCACHE=$EVID/scratch/gocache GOPATH=$EVID/scratch/gopath GOTMPDIR=$EVID/tmp
mkdir -p "$GOBIN"
echo "date=$(date -u +%FT%TZ) go=$(go version)"
echo "=== control: OSV query with versions known to be old (expect advisories) ==="
python3 -I - <<'EOF'
import json, urllib.request
q = {"queries": [
 {"package": {"ecosystem": "Go", "name": "github.com/jackc/pgx/v5"}, "version": "5.9.1"},
 {"package": {"ecosystem": "Maven", "name": "io.netty:netty-codec-http"}, "version": "4.1.0.Final"},
 {"package": {"ecosystem": "Go", "name": "stdlib"}, "version": "1.20.0"}]}
r = urllib.request.Request("https://api.osv.dev/v1/querybatch", data=json.dumps(q).encode(), headers={"Content-Type": "application/json"})
for x in json.load(urllib.request.urlopen(r, timeout=60))["results"]:
    print("control ->", len(x.get("vulns", [])), "advisories", [v["id"] for v in x.get("vulns", [])][:4])
EOF
echo "=== install pinned scanners ==="
t0=$(now_ms); go install golang.org/x/vuln/cmd/govulncheck@v1.8.0 2>&1 | tail -3; echo "govulncheck_install_ms=$(( $(now_ms) - t0 ))"
t0=$(now_ms); go install github.com/google/osv-scanner/v2/cmd/osv-scanner@v2.6.0 2>&1 | tail -3; echo "osv_scanner_install_ms=$(( $(now_ms) - t0 ))"
ls -la "$GOBIN"
"$GOBIN/govulncheck" -version 2>&1 | head -4
"$GOBIN/osv-scanner" --version 2>&1 | head -3
echo "=== govulncheck on the Go probe (source mode and binary mode) ==="
(cd "$EVID/scratch/s10/a" && "$GOBIN/govulncheck" ./... 2>&1 | tail -8)
"$GOBIN/govulncheck" -mode=binary "$EVID/scratch/s10/a/probe-go" 2>&1 | tail -8
echo "=== osv-scanner on the Ktor probe lockfile and verification metadata ==="
mkdir -p "$EVID/scratch/s14/ktor" "$EVID/scratch/s14/control"
cp "$EVID/s11-gradle.lockfile" "$EVID/scratch/s14/ktor/gradle.lockfile"
mkdir -p "$EVID/scratch/s14/ktor/gradle"; cp "$EVID/s11-verification-metadata.xml" "$EVID/scratch/s14/ktor/gradle/verification-metadata.xml"
"$GOBIN/osv-scanner" scan source --recursive "$EVID/scratch/s14/ktor" 2>&1 | tail -15
echo "=== osv-scanner control: lockfile with an old Netty (expect findings) ==="
printf '# control\nio.netty:netty-codec-http:4.1.0.Final=runtimeClasspath\nempty=\n' > "$EVID/scratch/s14/control/gradle.lockfile"
"$GOBIN/osv-scanner" scan source --recursive "$EVID/scratch/s14/control" 2>&1 | tail -12
echo "=== go.sum / GOFLAGS=-mod=readonly / GONOSUMDB behaviour: go env of verification settings ==="
go env GOFLAGS GONOSUMDB GONOSUMCHECK GOSUMDB GOPROXY GOVCS
echo done
