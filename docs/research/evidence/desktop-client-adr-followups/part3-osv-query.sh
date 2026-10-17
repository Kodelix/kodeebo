#!/usr/bin/env bash
# Part 3 (owner Android) - OSV.dev advisory query + npm registry latest versions.
# Usage: bash part3-osv-query.sh   (network required). Date of run is printed.
set -u
echo "date: $(date -u +%F) tool: curl $(curl --version | head -1)"
echo "== npm registry latest =="
for p in @capacitor/core @capacitor/android @capacitor/push-notifications @capacitor/cli; do
  v=$(curl -s --max-time 20 "https://registry.npmjs.org/${p//\//%2F}/latest" | python3 -I -c 'import sys,json; print(json.load(sys.stdin).get("version","?"))' 2>/dev/null)
  echo "$p latest=$v"
done
q() { # ecosystem name version
  local body; body=$(printf '{"package":{"name":"%s","ecosystem":"%s"},"version":"%s"}' "$2" "$1" "$3")
  local out; out=$(curl -s --max-time 30 -X POST https://api.osv.dev/v1/query -d "$body")
  local n; n=$(printf '%s' "$out" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v), " ".join(x["id"] for x in v[:8]))' 2>/dev/null)
  echo "$1 $2 $3 -> advisories: ${n:-QUERY-FAILED}"
}
echo "== OSV =="
q Maven io.ktor:ktor-server-core 3.6.0
q Maven io.ktor:ktor-client-core 3.6.0
q Maven org.jetbrains.kotlin:kotlin-stdlib 2.4.21
q Maven org.jetbrains.compose.runtime:runtime 1.12.2
q Maven app.cash.sqldelight:runtime 2.4.1
q npm @capacitor/core 8.5.3
q npm @capacitor/android 8.5.3
q npm react 19.3.0
q npm vite 8.3.4
echo "== control (must be non-zero) =="
q npm electron 10.0.0
