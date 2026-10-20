#!/usr/bin/env bash
# S14b: details of repository advisories that may touch Gradle 9.7.0 / pgjdbc 42.7.14 / KGP 2.4.21 (GitHub REST, unauthenticated).
echo "date: $(date -u +%FT%TZ)"
for r in gradle/gradle pgjdbc/pgjdbc; do
 echo "=== $r"
 curl -s -m 30 -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/$r/security-advisories?per_page=100" | python3 -I -c '
import sys,json
for x in json.load(sys.stdin):
  rng=[(v.get("package") or {}).get("name","?")+" | "+str(v.get("vulnerable_version_range"))+" | fixed "+str(v.get("patched_versions")) for v in x.get("vulnerabilities",[])]
  print(x["ghsa_id"],x.get("cve_id"),x.get("published_at","")[:10],x.get("severity"),"|",(x.get("summary") or "")[:150],"|",rng[:2])'
done
echo "=== GHSA-r937-wjx7-w2jp (listed by OSV for kotlin-gradle-plugin, all versions)"
curl -s -m 30 -H 'Accept: application/vnd.github+json' https://api.github.com/advisories/GHSA-r937-wjx7-w2jp | python3 -I -c '
import sys,json
x=json.load(sys.stdin); print(x.get("ghsa_id"),x.get("cve_id"),x.get("published_at","")[:10],x.get("severity"),"|",x.get("summary"),"|",[ (v["package"]["name"],v.get("vulnerable_version_range"),v.get("first_patched_version")) for v in x.get("vulnerabilities",[])], x.get("html_url"))'
