#!/bin/bash
# S10: read-only metadata queries (no artifact is downloaded). Maven Central HEAD/metadata, GitHub latest releases, OSV API.
set -u
M=https://repo1.maven.org/maven2
echo "date_utc: $(date -u +%FT%TZ)"
echo "== artifact sizes (HEAD only)"
for a in org/flywaydb/flyway-core/13.10.3/flyway-core-13.10.3.jar org/flywaydb/flyway-database-postgresql/13.10.3/flyway-database-postgresql-13.10.3.jar org/liquibase/liquibase-core/5.0.4/liquibase-core-5.0.4.jar org/postgresql/postgresql/42.7.14/postgresql-42.7.14.jar; do
  echo "-- $a"; curl -sI --max-time 30 "$M/$a" | grep -i -E "^(HTTP|content-length|last-modified)"
done
echo "== maven-metadata (latest/release/lastUpdated)"
for a in org/flywaydb/flyway-core org/flywaydb/flyway-database-postgresql org/liquibase/liquibase-core org/postgresql/postgresql; do
  echo "-- $a"; curl -s --max-time 30 "$M/$a/maven-metadata.xml" | grep -E "<latest>|<release>|<lastUpdated>"
done
echo "== flyway-core 13.10.3 pom (dependencies, licence)"
curl -s --max-time 30 "$M/org/flywaydb/flyway-core/13.10.3/flyway-core-13.10.3.pom" | grep -E "<groupId>|<artifactId>|<version>|<scope>|<optional>|<licenses>|<name>" | head -70
echo "== liquibase-core 5.0.4 pom (dependencies, licence)"
curl -s --max-time 30 "$M/org/liquibase/liquibase-core/5.0.4/liquibase-core-5.0.4.pom" | grep -E "<groupId>|<artifactId>|<version>|<scope>|<optional>|<licenses>|<name>|<url>" | head -70
echo "== GitHub latest releases"
for r in amacneil/dbmate pressly/goose golang-migrate/migrate; do
  curl -s --max-time 30 "https://api.github.com/repos/$r/releases/latest" | python3 -I -c 'import sys,json
d=json.load(sys.stdin); print(sys.argv[1], d.get("tag_name"), d.get("published_at"), d.get("message",""))' "$r"
done
echo "== OSV (api.osv.dev/v1/query)"
osv(){ eco="$1"; name="$2"; ver="$3"
  if [ -n "$ver" ]; then body="{\"package\":{\"ecosystem\":\"$eco\",\"name\":\"$name\"},\"version\":\"$ver\"}"; else body="{\"package\":{\"ecosystem\":\"$eco\",\"name\":\"$name\"}}"; fi
  echo "-- $eco $name ${ver:-<all versions>}"
  curl -s --max-time 60 -X POST https://api.osv.dev/v1/query -d "$body" | python3 -I -c 'import sys,json
d=json.load(sys.stdin); v=d.get("vulns",[]); print("count:",len(v))
for x in v: print(" ",x["id"],x.get("published","")[:10],"|",(x.get("summary") or "")[:110])'
}
osv Maven org.flywaydb:flyway-core 13.10.3
osv Maven org.flywaydb:flyway-core ""
osv Maven org.liquibase:liquibase-core 5.0.4
osv Maven org.liquibase:liquibase-core ""
osv Maven org.postgresql:postgresql 42.7.14
osv Go github.com/pressly/goose/v3 ""
osv Go github.com/golang-migrate/migrate/v4 ""
osv Go github.com/amacneil/dbmate/v2 ""
