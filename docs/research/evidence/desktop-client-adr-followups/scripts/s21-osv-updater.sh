#!/usr/bin/env bash
# S21 (part 2): read the OSV record of GHSA-9jxc-qjr9-vjxq; query OSV for electron-updater versions and builder-util-runtime 9.7.0;
# read the builder-util-runtime advisory returned by s20 for the guessed 9.5.1 (exploratory query, not a shipped version).
# Usage: s21-osv-updater.sh <fetched-dir>   (same dir s20 wrote to)
set -u
out="$1"
date -u +"run at %Y-%m-%dT%H:%MZ"
q() { curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query -d "{\"version\":\"$4\",\"package\":{\"name\":\"$2\",\"ecosystem\":\"$3\"}}" -H 'Content-Type: application/json' > "$out/osv-$1.json"
  echo "$1 $3:$2@$4 -> $(python3 -I -c 'import json,sys; d=json.load(open(sys.argv[1])); print(len(d.get("vulns",[])), [v["id"] for v in d.get("vulns",[])][:15])' "$out/osv-$1.json")"; }
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1]))
print("ID", d["id"], "aliases", d.get("aliases"), "published", d.get("published"), "modified", d.get("modified"))
print("SUMMARY", d.get("summary"))
for a in d.get("affected",[]): print("AFFECTED", a["package"], a.get("ranges"), a.get("versions"))
print("SEVERITY", d.get("severity")); print("REFS", [r["url"] for r in d.get("references",[])])
' "$out/osv-vuln-GHSA-9jxc-qjr9-vjxq.json"
curl -sS --max-time 30 https://api.osv.dev/v1/vulns/GHSA-p2f4-r6v6-j797 > "$out/osv-vuln-GHSA-p2f4-r6v6-j797.json"
python3 -I -c '
import json,sys
d=json.load(open(sys.argv[1]))
print("ID", d["id"], "aliases", d.get("aliases"), "published", d.get("published"))
print("SUMMARY", d.get("summary"))
for a in d.get("affected",[]): print("AFFECTED", a["package"], a.get("ranges"))
' "$out/osv-vuln-GHSA-p2f4-r6v6-j797.json"
q eu-6.8.9 electron-updater npm 6.8.9
q eu-6.8.10 electron-updater npm 6.8.10
q eu-6.3.0-alpha.5-control electron-updater npm 6.3.0-alpha.5
q eu-6.3.0-alpha.6 electron-updater npm 6.3.0-alpha.6
q bur-9.7.0 builder-util-runtime npm 9.7.0
q bur-9.5.1-guess builder-util-runtime npm 9.5.1
q electron-builder-all-cur electron-builder npm 26.16.0
