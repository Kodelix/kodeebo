#!/usr/bin/env bash
# S24: JVM-track spike. Needs docker, JDK 21, kotlinc 2.4.21 and the resolved classpath (see README.md).
# Usage: bash run.sh > output.txt 2>&1
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS=/tmp/ti-p2-tools; CP=$(ls $TOOLS/cp/*.jar | tr '\n' ':')
NET=ti-p2-net; PGP=58451; PGB=58452; PGB0=58453
cleanup() { docker rm -fv ti-p2-pg ti-p2-pgb ti-p2-pgb0 >/dev/null 2>&1; docker network rm $NET >/dev/null 2>&1; }
trap cleanup EXIT; cleanup
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "### $(java -version 2>&1 | head -1); $($TOOLS/kotlinc/bin/kotlinc -version 2>&1 | tail -1)"
echo "### classpath: $(ls $TOOLS/cp | tr '\n' ' ')"
OUT=$(mktemp -d); trap 'cleanup; rm -rf "$OUT"' EXIT
$TOOLS/kotlinc/bin/kotlinc -nowarn -cp "$CP" "$HERE/Spike.kt" -d "$OUT" 2>&1 | grep -v '^warning' || true
docker network create $NET >/dev/null
docker run -d --name ti-p2-pg --network $NET -p 127.0.0.1:$PGP:5432 -e POSTGRES_PASSWORD=ti_p2_super_throwaway postgres:18.6 >/dev/null
for i in $(seq 1 90); do docker exec ti-p2-pg pg_isready -h 127.0.0.1 -U postgres -q && break; sleep 1; done
sleep 2
echo "### server: $(docker exec ti-p2-pg postgres --version)"
docker exec -i ti-p2-pg psql -X -q -U postgres -d postgres -v ON_ERROR_STOP=1 < "$HERE/setup.sql" 2>&1 | tail -4
for pair in "200:$PGB:ti-p2-pgb" "0:$PGB0:ti-p2-pgb0"; do
  IFS=: read mps port name <<<"$pair"
  docker run -d --name $name --network $NET -p 127.0.0.1:$port:6432 --entrypoint pgbouncer \
    -v "$HERE/pgbouncer-mps$mps.ini:/etc/pgbouncer/pgbouncer.ini:ro" -v "$HERE/userlist.txt:/etc/pgbouncer/userlist.txt:ro" \
    edoburu/pgbouncer:v1.26.0-p0 /etc/pgbouncer/pgbouncer.ini >/dev/null
done
sleep 2
java -cp "$OUT:$CP" SpikeKt $PGP $PGB $PGB0 2>&1
echo "### exit code $?"
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
