#!/usr/bin/env bash
# S20 (part 2): OSV.dev + npm registry queries for the exact component versions of runtimes A and B.
# No secrets in queries. Usage: s20-osv-query.sh <outdir>   (outdir = fetched/ directory, empty or new)
# Adapted from docs/research/evidence/desktop-client-technology/part5-osv-query.sh
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
q() { # name ecosystem package version
  curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query \
    -d "{\"version\":\"$4\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$3\"}}" \
    -H 'Content-Type: application/json' > "$out/osv-$1.json"
  echo "$1 $3:$2@$4 -> $(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("vulns",[])), [v["id"] for v in d.get("vulns",[])][:15])' "$out/osv-$1.json")"
}
# Full advisory record from OSV
curl -sS --max-time 30 https://api.osv.dev/v1/vulns/GHSA-9jxc-qjr9-vjxq > "$out/osv-vuln-GHSA-9jxc-qjr9-vjxq.json"
echo "vuln record saved: $(wc -c < "$out/osv-vuln-GHSA-9jxc-qjr9-vjxq.json") bytes"
# npm registry metadata (what electron-builder 26.17.0 depends on; electron-updater versions)
curl -sS --max-time 30 https://registry.npmjs.org/electron-builder/26.17.0 > "$out/npm-electron-builder-26.17.0.json"
curl -sS --max-time 30 https://registry.npmjs.org/app-builder-lib/26.17.0 > "$out/npm-app-builder-lib-26.17.0.json"
curl -sS --max-time 60 https://registry.npmjs.org/electron-updater > "$out/npm-electron-updater-full.json"
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1])); print("electron-builder 26.17.0 deps:", d.get("dependencies"))
a=json.load(open(sys.argv[2])); print("app-builder-lib 26.17.0 deps:", {k:v for k,v in a.get("dependencies",{}).items() if "updater" in k or "publish" in k or "runtime" in k}, a.get("license"))
u=json.load(open(sys.argv[3])); print("electron-updater dist-tags:", u.get("dist-tags")); t=u.get("time",{});
vs=sorted([(t[v],v) for v in t if v[0].isdigit()])[-8:]; print("latest 8 electron-updater by time:", vs); print("license:", u.get("license"))
' "$out/npm-electron-builder-26.17.0.json" "$out/npm-app-builder-lib-26.17.0.json" "$out/npm-electron-updater-full.json"
# npm: runtime B
q electron electron npm 44.8.0
q electron-builder electron-builder npm 26.17.0
q app-builder-lib app-builder-lib npm 26.17.0
q bs3mc better-sqlite3-multiple-ciphers npm 13.0.3
q koffi koffi npm 2.16.3
q builder-util-runtime builder-util-runtime npm 9.5.1
# Maven: runtime A
q kotlin-stdlib org.jetbrains.kotlin:kotlin-stdlib Maven 2.4.21
q coroutines-core org.jetbrains.kotlinx:kotlinx-coroutines-core Maven 1.9.0
q willena-sqlite-jdbc io.github.willena:sqlite-jdbc Maven 3.53.4.0
q jna net.java.dev.jna:jna Maven 5.19.1
q cmp-desktop org.jetbrains.compose.desktop:desktop Maven 1.12.2
q cmp-ui org.jetbrains.compose.ui:ui Maven 1.12.2
q cmp-foundation org.jetbrains.compose.foundation:foundation Maven 1.12.2
q cmp-runtime org.jetbrains.compose.runtime:runtime Maven 1.12.2
q xerial-sqlite-jdbc-control org.xerial:sqlite-jdbc Maven 3.41.2.1
# Control: known old vulnerable electron returns >0
q control-electron-old electron npm 10.0.0
