#!/usr/bin/env bash
# Part 5 evidence: OSV.dev advisories for the exact versions discussed. No secrets in queries.
# Usage: part5-osv-query.sh <outdir>
set -u
out="$1"
q() { # name ecosystem package version
  curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query \
    -d "{\"version\":\"$4\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$3\"}}" \
    -H 'Content-Type: application/json' > "$out/osv-$1.json"
  echo "$1 $3:$2@$4 -> $(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("vulns",[])), [v["id"] for v in d.get("vulns",[])][:12])' "$out/osv-$1.json")"
}
date -u +"run at %Y-%m-%dT%H:%MZ"
q electron electron npm 44.8.0
q tauri tauri crates.io 2.12.4
q ktor-client-core io.ktor:ktor-client-core Maven 3.6.0
q capacitor-core @capacitor/core npm 8.5.3
q react-native react-native npm 0.88.0
q react-native-084 react-native npm 0.84.0
q openapi-generator org.openapitools:openapi-generator Maven 7.26.0
q sqldelight-sqlite-driver app.cash.sqldelight:sqlite-driver Maven 2.4.1
# Control: a known-old vulnerable version must return >0 (proves the endpoint answers)
q control-electron-old electron npm 10.0.0
