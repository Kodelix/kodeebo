#!/usr/bin/env bash
# S21: current versions (Go proxy, Maven metadata) and OSV advisories for the libraries this part names; then
# the jars the JDBC spike S22 needs (HEAD sizes printed first; refuses to fetch a jar above 20 MB).
# Usage: bash run.sh > output.txt 2>&1.   Queries contain only public package names and versions.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../../../.." && pwd)"
JARS="$ROOT/production/session-state/cache/backend-track/part-2/jars"
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "## Go proxy @latest"
for m in github.com/riverqueue/river github.com/riverqueue/river/riverdriver/riverpgxv5 github.com/jackc/pgx/v5; do
  echo "$m -> $(curl -sS -m 30 "https://proxy.golang.org/$m/@latest")"
done
echo "## Maven metadata (latest/release/lastUpdated)"
for ga in org.postgresql/postgresql com.github.kagkarlsson/db-scheduler com.zaxxer/HikariCP org.slf4j/slf4j-api; do
  g="${ga%%/*}"; a="${ga##*/}"; p="${g//./\/}"
  echo "$ga: $(curl -sS -m 30 "https://repo1.maven.org/maven2/$p/$a/maven-metadata.xml" | tr -d '\n ' | grep -o '<latest>[^<]*</latest>\|<release>[^<]*</release>\|<lastUpdated>[^<]*</lastUpdated>' | tr '\n' ' ')"
done
echo "## OSV queries (api.osv.dev /v1/query); a response of {} means no record"
q() { # ecosystem name version
  printf '%s %s %s -> ' "$1" "$2" "$3"
  curl -sS -m 30 -X POST https://api.osv.dev/v1/query -d "{\"package\":{\"name\":\"$2\",\"ecosystem\":\"$1\"},\"version\":\"$3\"}" \
   | python3 -I -c 'import sys,json; d=json.load(sys.stdin); v=d.get("vulns",[]); print(len(v),"records:", ", ".join(x["id"]+" ("+x.get("modified","?")[:10]+")" for x in v) if v else "{}")'
}
q Go github.com/jackc/pgx/v5 5.11.0
RV=$(curl -sS -m 30 "https://proxy.golang.org/github.com/riverqueue/river/@latest" | python3 -I -c 'import sys,json; print(json.load(sys.stdin)["Version"].lstrip("v"))')
q Go github.com/riverqueue/river "$RV"
q Maven org.postgresql:postgresql 42.7.14
q Maven com.zaxxer:HikariCP 7.1.0
q Maven org.jetbrains.exposed:exposed-core 1.5.1
DBS=$(curl -sS -m 30 https://repo1.maven.org/maven2/com/github/kagkarlsson/db-scheduler/maven-metadata.xml | tr -d '\n ' | grep -o '<release>[^<]*</release>' | sed 's/<[^>]*>//g')
q Maven com.github.kagkarlsson:db-scheduler "$DBS"
echo "## jar sizes (HEAD) then fetch, each jar in its own new directory"
SL=$(curl -sS -m 30 https://repo1.maven.org/maven2/org/slf4j/slf4j-api/maven-metadata.xml | tr -d '\n ' | grep -o '<release>[^<]*</release>' | sed 's/<[^>]*>//g')
for spec in "org/postgresql/postgresql/42.7.14/postgresql-42.7.14.jar" "com/zaxxer/HikariCP/7.1.0/HikariCP-7.1.0.jar" "org/slf4j/slf4j-api/$SL/slf4j-api-$SL.jar"; do
  url="https://repo1.maven.org/maven2/$spec"; name="$(basename "$spec")"
  size=$(curl -sSI -m 30 "$url" | tr -d '\r' | awk -F': ' 'tolower($1)=="content-length"{print $2}')
  echo "$name: ${size:-unknown} bytes"
  if [ -n "${size:-}" ] && [ "$size" -lt 20000000 ]; then
    d="$JARS/${name%.jar}"; mkdir -p "$d"; [ -z "$(ls -A "$d")" ] && curl -sS -m 120 -o "$d/$name" "$url"
    sha256sum "$d/$name"
  fi
done
echo "### jars total: $(du -sh "$JARS" | cut -f1)"
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
