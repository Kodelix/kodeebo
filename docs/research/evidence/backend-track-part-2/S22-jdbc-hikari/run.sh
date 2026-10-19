#!/usr/bin/env bash
# S22: HikariCP 7.1.0 + pgjdbc 42.7.14 (JDBC layer of the Ktor track) against postgres:18.6, same schema and seed as S20.
# Jars were fetched by S21-versions-osv/run.sh into production/session-state/cache/backend-track/part-2/jars/<name>/ (1.5 MB total).
# Usage: bash run.sh > output.txt 2>&1   Needs docker and JDK 21 (java Spike.java single-file launch).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../../../.." && pwd)"
S20="$HERE/../S20-go-pgx"
JARS="$ROOT/production/session-state/cache/backend-track/part-2/jars"
CP="$JARS/postgresql-42.7.14/postgresql-42.7.14.jar:$JARS/HikariCP-7.1.0/HikariCP-7.1.0.jar:$JARS/slf4j-api-2.1.0-alpha1/slf4j-api-2.1.0-alpha1.jar"
NAME=bt2-pg; PGP=58461
cleanup() { docker rm -fv $NAME >/dev/null 2>&1; }
trap cleanup EXIT; cleanup
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "### $(java -version 2>&1 | head -1); $(docker --version)"
docker run -d --name $NAME -p 127.0.0.1:$PGP:5432 -e POSTGRES_PASSWORD=bt2_super_throwaway postgres:18.6 >/dev/null
for i in $(seq 1 90); do docker exec $NAME pg_isready -h 127.0.0.1 -U postgres -q && break; sleep 1; done
sleep 2
echo "### server: $(docker exec $NAME postgres --version)"
docker exec -i $NAME psql -X -q -U postgres -d postgres -v ON_ERROR_STOP=1 < "$S20/setup.sql" >/dev/null 2>&1
docker exec -i $NAME psql -X -q -U postgres -d postgres -v ON_ERROR_STOP=1 < "$S20/seed.sql" >/dev/null 2>&1
cd "$HERE" && java -Xmx32m -cp "$CP" Spike.java 127.0.0.1:$PGP 2>&1
echo "### exit $?"
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
