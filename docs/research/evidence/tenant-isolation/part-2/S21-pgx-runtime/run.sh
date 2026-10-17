#!/usr/bin/env bash
# S21: pgx v5.11.0 + postgres:18.6 (+ PgBouncer 1.26.0 transaction mode) tenant-context spike.
# Usage: bash run.sh > output.txt 2>&1   Needs docker, go (1.27.x), network for the Go module proxy.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NET=ti-p2-net; PGP=58451; PGB=58452; PGB0=58453
cleanup() { docker rm -fv ti-p2-pg ti-p2-pgb ti-p2-pgb0 >/dev/null 2>&1; docker network rm $NET >/dev/null 2>&1; }
trap cleanup EXIT; cleanup
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"; echo "### $(go version); $(docker --version)"
echo "### images: postgres:18.6 $(docker image inspect postgres:18.6 --format '{{.Id}}' | cut -c1-19)  edoburu/pgbouncer:v1.26.0-p0 $(docker image inspect edoburu/pgbouncer:v1.26.0-p0 --format '{{.Id}}' | cut -c1-19)"
docker network create $NET >/dev/null
docker run -d --name ti-p2-pg --network $NET -p 127.0.0.1:$PGP:5432 -e POSTGRES_PASSWORD=ti_p2_super_throwaway postgres:18.6 >/dev/null
for i in $(seq 1 90); do docker exec ti-p2-pg pg_isready -h 127.0.0.1 -U postgres -q && break; sleep 1; done
sleep 2
echo "### server: $(docker exec ti-p2-pg postgres --version)"
docker exec -i ti-p2-pg psql -X -U postgres -d postgres -v ON_ERROR_STOP=1 < "$HERE/setup.sql" 2>&1
for pair in "200:$PGB:ti-p2-pgb" "0:$PGB0:ti-p2-pgb0"; do
  IFS=: read mps port name <<<"$pair"
  docker run -d --name $name --network $NET -p 127.0.0.1:$port:6432 --entrypoint pgbouncer \
    -v "$HERE/pgbouncer-mps$mps.ini:/etc/pgbouncer/pgbouncer.ini:ro" -v "$HERE/userlist.txt:/etc/pgbouncer/userlist.txt:ro" \
    edoburu/pgbouncer:v1.26.0-p0 /etc/pgbouncer/pgbouncer.ini >/dev/null
done
sleep 2
echo "### pgbouncer containers up: $(docker ps --filter name=ti-p2-pgb --format '{{.Names}}' | tr '\n' ' ')"
cd "$HERE" && GOFLAGS=-mod=mod PG_DIRECT=127.0.0.1:$PGP PG_BOUNCER200=127.0.0.1:$PGB PG_BOUNCER0=127.0.0.1:$PGB0 \
  go test -count=1 -v ./... 2>&1
echo "### pgbouncer (mps=200) log tail"; docker logs --tail 15 ti-p2-pgb 2>&1
echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
