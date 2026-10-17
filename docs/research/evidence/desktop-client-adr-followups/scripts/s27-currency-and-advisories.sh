#!/usr/bin/env bash
# S27 (part 2): currency of shipped versions + vendor advisories: OSV for Skiko 0.150.2; Willena 3.53.4.0 and SQLite3MC 2.6.1 release notes (embedded SQLite version);
# Electron 44.x release list (npm registry) and Electron's published GitHub security advisories; Node 24.x latest; Adoptium latest JDK 21 build.
# Usage: s27-currency-and-advisories.sh <outdir>
set -u
out="$1"; mkdir -p "$out"
date -u +"run at %Y-%m-%dT%H:%MZ"
q() { curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query -d "{\"version\":\"$4\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$3\"}}" -H 'Content-Type: application/json' > "$out/osv-$1.json"
  echo "$1 $3:$2@$4 -> $(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("vulns",[])), [v["id"] for v in d.get("vulns",[])][:15])' "$out/osv-$1.json")"; }
q skiko-awt org.jetbrains.skiko:skiko-awt Maven 0.150.2
q skiko-awt-runtime-windows-x64 org.jetbrains.skiko:skiko-awt-runtime-windows-x64 Maven 0.150.2
echo "== Willena 3.53.4.0 release body"; gh api repos/Willena/sqlite-jdbc-crypt/releases/tags/3.53.4.0 --jq '.tag_name+" | "+.published_at+"\n"+.body' | head -30 | tee "$out/willena-3.53.4.0-release.txt"
echo "== SQLite3MC v2.6.1 release body (head)"; gh api repos/utelle/SQLite3MultipleCiphers/releases/tags/v2.6.1 --jq '.tag_name+" | "+.published_at+"\n"+.body' | head -25 | tee "$out/sqlite3mc-2.6.1-release.txt"
echo "== Electron: npm registry dist-tags and 44.x list"
curl -sS --max-time 60 https://registry.npmjs.org/electron > "$out/npm-electron-full.json"
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1])); t=d["time"]
print("dist-tags:", d["dist-tags"])
v44=sorted([(t[v],v) for v in t if v.startswith("44.") and "-" not in v]); print("44.x stable by time:", v44[-8:])
print("latest overall stable by time:", sorted([(t[v],v) for v in t if v[0].isdigit() and "-" not in v])[-4:])
' "$out/npm-electron-full.json"
echo "== Electron published security advisories (GitHub API), title/severity/vulnerable ranges for npm electron"
gh api "repos/electron/electron/security-advisories?state=published&per_page=100" > "$out/electron-ghsa-list.json" 2>"$out/electron-ghsa-list.err" || head -c 300 "$out/electron-ghsa-list.err"
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1])); print("count:", len(d))
for a in sorted(d, key=lambda x:x.get("published_at",""))[-12:]:
    vs=[(v["package"]["name"], v.get("vulnerable_version_range"), v.get("patched_versions")) for v in a.get("vulnerabilities",[])]
    print(a["ghsa_id"], a.get("cve_id"), a.get("severity"), a.get("published_at","")[:10], "|", a["summary"][:90], "|", vs)
' "$out/electron-ghsa-list.json"
echo "== Node 24.x latest (nodejs.org dist index)"
curl -sS --max-time 30 https://nodejs.org/dist/index.json > "$out/node-index.json"
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1])); r=[x for x in d if x["version"].startswith("v24.")][:4]
print([(x["version"],x["date"],x.get("security")) for x in r])
' "$out/node-index.json"
echo "== Adoptium latest JDK 21 (api.adoptium.net)"
curl -sS --max-time 30 "https://api.adoptium.net/v3/assets/latest/21/hotspot?architecture=x64&image_type=jdk&os=windows" > "$out/adoptium-latest-21.json"
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1]));
for x in d[:2]: print(x["release_name"], x["version"]["semver"], x["binary"]["updated_at"], x["binary"]["package"]["name"])
' "$out/adoptium-latest-21.json"
