#!/bin/bash
# S56: read OSV record GO-2026-4919 (structure only: aliases, affected packages, ranges, events, versions).
# Usage: s56-osv-record.sh <evidence_dir>
set -u
E="$1"
echo "date_utc: $(date -u +%FT%TZ)"
curl -fsS --max-time 30 https://api.osv.dev/v1/vulns/GO-2026-4919 -o "$E/osv-GO-2026-4919.json" || { echo fetch failed; exit 1; }
python3 -I - "$E/osv-GO-2026-4919.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
print("id",r.get("id"),"aliases",r.get("aliases"),"published",r.get("published"),"modified",r.get("modified"),"withdrawn",r.get("withdrawn"))
print("top-level keys",sorted(r))
for a in r.get("affected",[]):
    print("AFFECTED package",a.get("package"))
    for rg in a.get("ranges",[]): print("  range type",rg.get("type"),"events",rg.get("events"))
    vs=a.get("versions"); print("  explicit versions:",None if vs is None else (len(vs), vs[:12]))
    print("  ecosystem_specific",json.dumps(a.get("ecosystem_specific"))[:300])
    print("  database_specific",json.dumps(a.get("database_specific"))[:300])
print("references (types/urls)",[(x.get("type"),x.get("url")) for x in r.get("references",[])][:8])
print("database_specific",json.dumps(r.get("database_specific"))[:300])
PY
