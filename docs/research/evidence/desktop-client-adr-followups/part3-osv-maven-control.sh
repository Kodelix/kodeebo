#!/usr/bin/env bash
# Part 3 - Maven control for OSV (F313) plus the two packages F312 did not query.
set -u
echo "date: $(date -u +%F)"
q() { body=$(printf '{"package":{"name":"%s","ecosystem":"%s"},"version":"%s"}' "$2" "$1" "$3")
  out=$(curl -s --max-time 30 -X POST https://api.osv.dev/v1/query -d "$body")
  n=$(printf '%s' "$out" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v), " ".join(x["id"] for x in v[:5]))' 2>/dev/null)
  echo "$1 $2 $3 -> advisories: ${n:-QUERY-FAILED}"; }
echo "== Maven control (must be non-zero) =="
q Maven org.apache.logging.log4j:log4j-core 2.14.1
q Maven io.ktor:ktor-server-core 2.0.0
echo "== not queried in F312 =="
q npm @capacitor/push-notifications 8.1.3
q Maven io.ktor:ktor-serialization-kotlinx-json 3.6.0
