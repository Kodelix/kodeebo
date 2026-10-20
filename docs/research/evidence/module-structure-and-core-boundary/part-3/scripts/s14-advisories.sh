#!/usr/bin/env bash
# S14 (tier E query of tier-3 sources): OSV + GitHub advisories for the components of part 3. No secrets, no auth. Date in output.
set -u
echo "date: $(date -u +%FT%TZ)"
osv() { # eco name version
  local body; if [ -n "$3" ]; then body="{\"package\":{\"ecosystem\":\"$1\",\"name\":\"$2\"},\"version\":\"$3\"}"; else body="{\"package\":{\"ecosystem\":\"$1\",\"name\":\"$2\"}}"; fi
  echo "OSV $1 $2 ${3:-ALL-VERSIONS}: $(curl -s -m 30 -X POST https://api.osv.dev/v1/query -d "$body" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v),"records",[ (x["id"],x.get("published","")[:10]) for x in v][:12], "(next page)" if d.get("next_page_token") else "")')"
}
for v in "org.flywaydb:flyway-core 13.10.3" "org.flywaydb:flyway-database-postgresql 13.10.3" "org.postgresql:postgresql 42.7.14" "org.jetbrains.kotlin:kotlin-gradle-plugin 2.4.21" "org.jetbrains.kotlin:kotlin-gradle-plugin-api 2.4.21" "org.gradle:gradle-core 9.7.0" "org.gradle:gradle-tooling-api 9.7.0"; do set -- $v; osv Maven $1 $2; done
osv Maven org.flywaydb:flyway-core ""
osv Maven org.jetbrains.kotlin:kotlin-gradle-plugin ""
osv Maven org.postgresql:postgresql ""
echo "--- GitHub global advisories (affects= filter, ecosystem maven)"
for a in "org.flywaydb:flyway-core@13.10.3" "org.postgresql:postgresql@42.7.14" "org.jetbrains.kotlin:kotlin-gradle-plugin@2.4.21"; do
  echo "GHSA affects=$a: $(curl -s -m 30 -H 'Accept: application/vnd.github+json' "https://api.github.com/advisories?ecosystem=maven&affects=$a&per_page=30" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print(len(d),[ (x["ghsa_id"],x.get("published_at","")[:10]) for x in d] if isinstance(d,list) else d)')"
done
echo "--- repository security advisories (published, per repo)"
for r in flyway/flyway pgjdbc/pgjdbc JetBrains/kotlin gradle/gradle; do
  echo "repo $r: $(curl -s -m 30 -H 'Accept: application/vnd.github+json' "https://api.github.com/repos/$r/security-advisories?per_page=100" | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print(len(d),"published; newest 5:",[(x["ghsa_id"],x.get("cve_id"),x.get("published_at","")[:10],x.get("severity"),[ (v.get("package") or {}).get("name")+" "+str(v.get("vulnerable_version_range"))+" fixed "+str(v.get("patched_versions")) for v in x.get("vulnerabilities",[])][:2]) for x in d[:5]] if isinstance(d,list) else d)')"
done
echo "--- Gradle: GitHub global advisories for the gradle repo name (any ecosystem)"
echo "GHSA gradle/gradle (via repo list above); GHSA affects= for org.gradle: $(curl -s -m 30 -H 'Accept: application/vnd.github+json' 'https://api.github.com/advisories?ecosystem=maven&affects=org.gradle:gradle-core@9.7.0&per_page=30' | python3 -I -c 'import sys,json; d=json.load(sys.stdin); print(len(d), [x["ghsa_id"] for x in d] if isinstance(d,list) else d)')"
