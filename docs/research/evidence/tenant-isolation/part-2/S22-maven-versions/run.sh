#!/usr/bin/env bash
# S22: current versions and release dates from Maven Central (tier 3: official repository metadata) + Go proxy for testcontainers-go.
# Usage: bash run.sh > output.txt 2>&1
set -u
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
M=https://repo1.maven.org/maven2
for a in org/postgresql/postgresql com/zaxxer/HikariCP org/jetbrains/exposed/exposed-core org/jetbrains/exposed/exposed-jdbc org/jetbrains/exposed/exposed-r2dbc org/jooq/jooq org/testcontainers/postgresql org/testcontainers/testcontainers org/jetbrains/kotlinx/kotlinx-coroutines-core; do
  echo; echo "== $a"
  x=$(curl -sS "$M/$a/maven-metadata.xml")
  echo "$x" | grep -E "<(latest|release|lastUpdated)>"
  echo "last 6 versions: $(echo "$x" | grep -o '<version>[^<]*</version>' | sed 's/<[^>]*>//g' | grep -viE 'alpha|beta|rc|m[0-9]|snapshot' | tail -6 | tr '\n' ' ')"
  rel=$(echo "$x" | grep -oP '(?<=<release>)[^<]*')
  ln=$(echo "$a" | awk -F/ '{print $NF}')
  echo "pom Last-Modified for release $rel: $(curl -sSI "$M/$a/$rel/$ln-$rel.pom" | grep -i '^last-modified')"
done
echo; echo "== exposed 1.5.1 / HikariCP 7.1.0 / pgjdbc: exact files"
for u in org/jetbrains/exposed/exposed-core/1.5.1/exposed-core-1.5.1 org/jetbrains/exposed/exposed-jdbc/1.5.1/exposed-jdbc-1.5.1 com/zaxxer/HikariCP/7.1.0/HikariCP-7.1.0; do
  echo "$u.pom: $(curl -sSI "$M/$u.pom" | grep -iE '^(HTTP|last-modified)' | tr '\n' ' ')"
done
echo; echo "== testcontainers-go via Go proxy"
curl -sS https://proxy.golang.org/github.com/testcontainers/testcontainers-go/@latest; echo
curl -sS https://proxy.golang.org/github.com/testcontainers/testcontainers-go/modules/postgres/@latest; echo
echo; echo "== PgBouncer downloads page: versions listed"
curl -sS https://www.pgbouncer.org/downloads/ | grep -o 'pgbouncer-[0-9.]*\.tar\.gz' | sort -uV | tail -4
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
