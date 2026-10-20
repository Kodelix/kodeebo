#!/bin/bash
# S54: advisory searches for the versions under test. Queries contain only public package coordinates.
# OSV API (api.osv.dev) and the GitHub global advisory database REST API (api.github.com/advisories).
set -u
echo "date_utc: $(date -u +%FT%TZ)"
osv() { # ecosystem name version
  echo "--- OSV $1 $2 $3"
  curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"ecosystem\":\"$1\",\"name\":\"$2\"},\"version\":\"$3\"}" \
   | python3 -I -c 'import json,sys;d=json.load(sys.stdin);v=d.get("vulns",[]);print(" records:",len(v));[print("  ",x["id"],x.get("published","")[:10],"|",(x.get("summary") or "")[:110]) for x in v]'
}
osv Go github.com/aquasecurity/trivy 0.76.0
osv Go github.com/aquasecurity/trivy-db 0.0.0-20261020000000-000000000000
osv Maven org.flywaydb:flyway-core 13.10.3
osv Maven org.flywaydb:flyway-database-postgresql 13.10.3
osv Maven org.postgresql:postgresql 42.7.14
echo; echo "--- OSV all versions (no version filter): Go trivy / Maven flyway-core"
for q in '{"package":{"ecosystem":"Go","name":"github.com/aquasecurity/trivy"}}' '{"package":{"ecosystem":"Maven","name":"org.flywaydb:flyway-core"}}'; do
  curl -sS --max-time 30 -X POST https://api.osv.dev/v1/query -d "$q" | python3 -I -c 'import json,sys;d=json.load(sys.stdin);v=d.get("vulns",[]);print(" records:",len(v));[print("  ",x["id"],x.get("published","")[:10],"|",(x.get("summary") or "")[:100]) for x in sorted(v,key=lambda x:x.get("published",""))[-12:]]'
done
gh() { echo; echo "--- GitHub advisory DB: $*"; curl -sS --max-time 30 -H "Accept: application/vnd.github+json" "https://api.github.com/advisories?per_page=30&$1" \
  | python3 -I -c 'import json,sys;d=json.load(sys.stdin);print(" records:",len(d) if isinstance(d,list) else d);[print("  ",x["ghsa_id"],x.get("cve_id"),x["severity"],x["published_at"][:10],"|",x["summary"][:90]) for x in (d if isinstance(d,list) else [])]'; }
gh "ecosystem=go&affects=github.com/aquasecurity/trivy@0.76.0"
gh "ecosystem=maven&affects=org.flywaydb:flyway-core@13.10.3"
gh "ecosystem=maven&affects=org.postgresql:postgresql@42.7.14"
echo; echo "--- all GitHub advisories (any version) for github.com/aquasecurity/trivy, newest first"
curl -sS --max-time 30 -H "Accept: application/vnd.github+json" "https://api.github.com/advisories?per_page=30&ecosystem=go&affects=github.com/aquasecurity/trivy" \
 | python3 -I -c 'import json,sys;d=json.load(sys.stdin);[print("  ",x["ghsa_id"],x.get("cve_id"),x["severity"],x["published_at"][:10],"vulnerable:",[ (v.get("package",{}).get("name"),v.get("vulnerable_version_range"),v.get("first_patched_version")) for v in x.get("vulnerabilities",[])][:2],"|",x["summary"][:70]) for x in d]'
