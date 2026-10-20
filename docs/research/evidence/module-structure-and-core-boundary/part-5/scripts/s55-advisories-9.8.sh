#!/usr/bin/env bash
# S55 (tier E, part 5): advisories for Gradle 9.8.1 / 9.8.2 and KGP 2.4.21: repository advisory list (GitHub REST, unauthenticated) and OSV (Maven).
echo "date: $(date -u +%FT%TZ)"
echo "=== gradle/gradle repository advisories (published), newest first"
curl -s -m 30 -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/gradle/gradle/security-advisories?per_page=100" | python3 -I -c '
import sys,json
d=json.load(sys.stdin)
if isinstance(d,dict): print("API message:",d.get("message")); sys.exit()
d.sort(key=lambda x:x.get("published_at",""),reverse=True)
for x in d[:12]:
  rng=[(v.get("package") or {}).get("name","?")+" | "+str(v.get("vulnerable_version_range"))+" | fixed "+str(v.get("patched_versions")) for v in x.get("vulnerabilities",[])]
  print(x["ghsa_id"],x.get("cve_id"),x.get("published_at","")[:10],x.get("severity"),"|",(x.get("summary") or "")[:110],"|",rng[:1])'
echo "=== OSV queries"
for q in "org.gradle:gradle-core 9.8.1" "org.gradle:gradle-core 9.8.2" "org.gradle:gradle-core 9.7.0" "org.jetbrains.kotlin:kotlin-gradle-plugin 2.4.21"; do
  set -- $q
  printf '%s %s: ' "$1" "$2"
  curl -s -m 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$1\",\"ecosystem\":\"Maven\"},\"version\":\"$2\"}" | python3 -I -c '
import sys,json
d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v),"records", [x["id"] for x in v])'
done
